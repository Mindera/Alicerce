import Foundation

public enum NetworkPersistableStoreError: Swift.Error {
    case network(Error)
    case decode(Error)
    case persistence(Error)
    case cancelled(Error?)
    case multiple([Error])
}

public class NetworkPersistableStore<Network: NetworkStack, Persistence: PersistenceStack>: NetworkStore
where Network.Remote == Data, Network.Request == URLRequest, Network.Response == URLResponse,
      Persistence.Remote == Data {

    public typealias Remote = Data
    public typealias Request = URLRequest
    public typealias Response = URLResponse
    public typealias E = NetworkPersistableStoreError

    public typealias FetchCompletionClosure<T> = NetworkStoreFetchCompletionClosure<T, Response, E>

    private let networkStack: Network
    private let persistenceStack: Persistence
    private let performanceMetrics: NetworkStorePerformanceMetricsTracker?

    public init(networkStack: Network,
                persistenceStack: Persistence,
                performanceMetrics: NetworkStorePerformanceMetricsTracker?) {
        self.networkStack = networkStack
        self.persistenceStack = persistenceStack
        self.performanceMetrics = performanceMetrics
    }

    // MARK: - Public Methods

    @discardableResult
    public func fetch<R: FetchResource>(resource: R,
                                        completion: @escaping FetchCompletionClosure<R.Internal>) -> Cancelable
    where R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

        // TODO: change the callback structure to allow returning multiple values (+ completion)

        switch resource.strategy {
        case .networkThenPersistence: return fetchNetworkFirst(resource: resource, completion: completion)
        case .persistenceThenNetwork: return fetchPersistenceFirst(resource: resource, completion: completion)
        }
    }

    public func clearPersistence(completion: @escaping (Result<Void, E>) -> Void) {
        persistenceStack.removeAll(completion: { completion($0.mapError { E.persistence($0) }) })
    }

    // MARK: - Private Methods

    private func fetchNetworkFirst<R>(resource: R,
                                      completion: @escaping FetchCompletionClosure<R.Internal>) -> Cancelable
    where R: NetworkStore.FetchResource,
          R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

        let cancelable = CancelableBag()

        cancelable += networkFetch(
            resource,
            success: { [weak self ] payload in
                self?.processFromNetwork(payload,
                                         resource: resource,
                                         cancelable: cancelable,
                                         completion: completion) ?? completion(.failure(.cancelled(nil)))
            },
            cancelled: { completion(.failure(.cancelled($0))) },
            failure: { [weak self] networkError in
                // Check if it's cancelled
                guard let strongSelf = self, cancelable.isCancelled == false
                    else { return completion(.failure(.network(networkError))) }

                // try to fetch data from the Persistence as a fallback
                strongSelf.persistenceFetch(
                    resource,
                    cacheHit: { [weak self] payload in
                        self?.processFromCache(payload,
                                               resource: resource,
                                               cancelable: cancelable,
                                               completion: completion) ?? completion(.failure(.cancelled(nil)))
                    },
                    cacheMiss: { completion(.failure(.network(networkError))) },
                    failure: { completion(.failure(.multiple([networkError, $0]))) })
            })

        return cancelable
    }

    @discardableResult
    private func fetchPersistenceFirst<R>(resource: R, // swiftlint:disable:this function_body_length
                                          completion: @escaping FetchCompletionClosure<R.Internal>)
    -> Cancelable
    where R: FetchResource,
          R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

        let cancelable = CancelableBag()

        // try to fetch data from the Persistence
        persistenceFetch(
            resource,
            cacheHit: { [weak self] payload in
                guard let strongSelf = self else { return completion(.failure(.cancelled(nil))) }

                // parse the new value from the cached data
                strongSelf.processFromCache(payload,
                                            resource: resource,
                                            cancelable: cancelable,
                                            completion: completion)

                // fetch the result from the network and update the cache in the background
                cancelable += strongSelf.networkFetch(
                    resource,
                    success: { [weak self ] payload in
                        self?.processFromNetwork(payload,
                                                 resource: resource,
                                                 cancelable: cancelable,
                                                 completion: { _ in })
                    },
                    cancelled: { _ in },
                    failure: { error in
                        Log.internalLogger.warning("⚠️ Failed to fetch value for '\(resource)' with error: \(error)")
                    })
            },
            cacheMiss: { [weak self] in
                guard let strongSelf = self else { return completion(.failure(.cancelled(nil))) }

                // try to fetch data from Network on cache/persistence miss
                cancelable += strongSelf.networkFetch(
                    resource,
                    success: { [weak self ] payload in
                        self?.processFromNetwork(payload,
                                                 resource: resource,
                                                 cancelable: cancelable,
                                                 completion: completion) ?? completion(.failure(.cancelled(nil)))
                    },
                    cancelled: { completion(.failure(.cancelled($0))) },
                    failure: { completion(.failure(.network($0))) }) // cache miss, return the network error
            },
            failure: { [weak self] persistenceError in
                guard let strongSelf = self else { return completion(.failure(.cancelled(nil))) }

                // try to fetch data from Network on persistence error
                cancelable += strongSelf.networkFetch(
                    resource,
                    success: { [weak self ] payload in
                        self?.processFromNetwork(payload,
                                                 resource: resource,
                                                 cancelable: cancelable,
                                                 completion: completion) ?? completion(.failure(.cancelled(nil)))
                    },
                    cancelled: { completion(.failure(.cancelled($0))) },
                    failure: { completion(.failure(.multiple([persistenceError, $0]))) })
            })

        return cancelable
    }

    // MARK: Processing Methods

    private func processFromNetwork<R>(_ payload: Alicerce.Network.Value<Remote, Response>,
                                       resource: R,
                                       cancelable: CancelableBag,
                                       completion: @escaping FetchCompletionClosure<R.Internal>)
    where R: NetworkResource & ExternalErrorDecoderResource & DecodableResource & PersistableResource,
          R.External == Remote, R.ExternalMetadata == Response {

        // Check if it's cancelled
        guard cancelable.isCancelled == false else {
            completion(.failure(.cancelled(nil)))
            return
        }

        // parse the new value from the data
        let value: R.Internal
        do {
            value = try decode(payload: payload.value, for: resource)
        } catch {
            // try to extract an API error if by any reason decoding failed
            let apiError = resource.decodeError(payload.value, payload.response)
            completion(.failure(.decode(apiError ?? error)))
            return
        }

        // Check if it's cancelled
        guard cancelable.isCancelled == false else {
            completion(.failure(.cancelled(nil)))
            return
        }

        persistenceStack.setObject(payload.value, for: resource.persistenceKey) {
            switch $0 {
            case .success: break
            case .failure(let error):
                Log.internalLogger.warning("⚠️ Failed to persist value for '\(resource)' with error: \(error)")
            }
        }

        completion(.success(.network(value, payload.response)))
    }

    private func processFromCache<R>(_ payload: Remote,
                                     resource: R,
                                     cancelable: CancelableBag,
                                     completion: @escaping FetchCompletionClosure<R.Internal>)
    where R: NetworkResource & DecodableResource & PersistableResource, R.External == Remote {

        // Check if it's cancelled
        guard cancelable.isCancelled == false else {
            completion(.failure(.cancelled(nil)))
            return
        }

        // parse the new value from the data
        let value: R.Internal
        do {
            value = try decode(payload: payload, for: resource)
        } catch {
            completion(.failure(.decode(error)))

            persistenceStack.removeObject(for: resource.persistenceKey) {
                switch $0 {
                case .success: break
                case .failure(let error):
                    Log.internalLogger.warning("⚠️ Failed to remove value for '\(resource)' with error: \(error)")
                }
            }

            return
        }

        // Check if it's cancelled
        guard cancelable.isCancelled == false else {
            completion(.failure(.cancelled(nil)))
            return
        }

        completion(.success(.persistence(value)))
    }

    // MARK: Fetch Methods

    private func networkFetch<R>(_ resource: R,
                                 success: @escaping (Alicerce.Network.Value<Remote, Response>) -> Void,
                                 cancelled: @escaping (Error) -> Void,
                                 failure: @escaping (Error) -> Void) -> Cancelable
    where R: NetworkStore.FetchResource,
          R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

        let cancelable = CancelableBag()

        cancelable += networkStack.fetch(resource: resource) { result in
            switch result {
            case .success(let response):
                success(response)
            case .failure(let error) where cancelable.isCancelled:
                cancelled(error)
            case .failure(let error):
                failure(error)
            }
        }

        return cancelable
    }

    private func persistenceFetch<R>(_ resource: R,
                                     cacheHit: @escaping (Data) -> Void,
                                     cacheMiss: @escaping () -> Void,
                                     failure: @escaping (Error) -> Void)
    where R: PersistableResource {

        persistenceStack.object(for: resource.persistenceKey) { result in
            switch result {
            case .success(let data?):
                cacheHit(data)
            case .success(nil):
                cacheMiss()
            case .failure(let error):
                failure(error)
            }
        }
    }

    // MARK: Parsing Methods

    private func decode<R: DecodableResource>(payload: Remote, for resource: R) throws -> R.Internal
    where R.External == Remote {

        guard let performanceMetrics = performanceMetrics else { return try resource.decode(payload) }

        let metadata: PerformanceMetrics.Metadata = [performanceMetrics.modelTypeMetadataKey : "\(R.Internal.self)",
            performanceMetrics.payloadSizeMetadataKey : UInt64(payload.count)]

        return try performanceMetrics.measureDecode(of: resource, payload: payload, metadata: metadata) {
            try resource.decode(payload)
        }
    }
}
