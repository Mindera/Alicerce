import Foundation
import Result

public enum NetworkPersistableStoreError: Swift.Error {
    case network(Network.Error)
    case parse(Parse.Error)
    case persistence(Swift.Error)
    case cancelled
    case other(Swift.Error)
    case multiple([Swift.Error])
}

public class NetworkPersistableStore<Network: NetworkStack, Persistence: PersistenceStack>: NetworkStore
where Network.Remote == Data, Network.Request == URLRequest, Network.Response == URLResponse,
      Persistence.Remote == Data {

    public typealias Remote = Data
    public typealias Request = URLRequest
    public typealias Response = URLResponse
    public typealias E = NetworkPersistableStoreError

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
    public func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>) -> Cancelable
    where R: NetworkResource & PersistableResource & StrategyFetchResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response
    {

        // TODO: change the callback structure to allow returning multiple values (+ completion)

        switch resource.strategy {
        case .networkThenPersistence: return fetchNetworkFirst(resource: resource, completion: completion)
        case .persistenceThenNetwork: return fetchPersistenceFirst(resource: resource, completion: completion)
        }
    }

    public func clearPersistence(completion: @escaping (Result<Void, E>) -> Void) {
        persistenceStack.removeAll(completion: { completion($0.mapError(E.persistence)) })
    }

    // MARK: - Private Methods

    private func fetchNetworkFirst<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>)
    -> Cancelable
    where R: NetworkResource & PersistableResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response {

        let cancelable = CancelableBag()

        let networkCancelable = networkFetch(
            resource,
            success: { [weak self ] payload in
                self?.process(payload,
                              fromCache: false,
                              resource: resource,
                              cancelable: cancelable,
                              completion: completion) ?? completion(.failure(.cancelled))
            },
            cancelled: { completion(.failure(.cancelled)) },
            failure: { [weak self] networkError in
                // Check if it's cancelled
                guard let strongSelf = self, cancelable.isCancelled == false
                else { return completion(.failure(.network(networkError))) }

                // try to fetch data from the Persistence as a fallback
                strongSelf.persistenceFetch(
                    resource,
                    cacheHit: { [weak self] payload in
                        self?.process(payload,
                                      fromCache: true,
                                      resource: resource,
                                      cancelable: cancelable,
                                      completion: completion) ?? completion(.failure(.cancelled))
                    },
                    cacheMiss: { completion(.failure(.network(networkError))) },
                    failure: { completion(.failure(.multiple([networkError, $0]))) })
        })

        cancelable.add(cancelable: networkCancelable)

        return cancelable
    }

    @discardableResult
    private func fetchPersistenceFirst<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>)
    -> Cancelable
    where R: NetworkResource & PersistableResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response {

        let cancelable = CancelableBag()

        // try to fetch data from the Persistence
        persistenceFetch(
            resource,
            cacheHit: { [weak self] payload in
                guard let strongSelf = self else { return completion(.failure(.cancelled)) }

                // parse the new value from the cached data
                strongSelf.process(payload,
                                   fromCache: true,
                                   resource: resource,
                                   cancelable: cancelable,
                                   completion: completion)

                // fetch the result from the network and update the cache in the background
                let networkCancelable = strongSelf.networkFetch(
                    resource,
                    success: { [weak self ] payload in
                        self?.process(payload,
                                      fromCache: false,
                                      resource: resource,
                                      cancelable: cancelable,
                                      completion: { _ in })
                    },
                    cancelled: {},
                    failure: { error in
                        print("⚠️ [Alicerce.NetworkPersistableStore]: Failed to fetch value for '\(resource)': \(error)")
                    })

                cancelable.add(cancelable: networkCancelable)
            },
            cacheMiss: { [weak self] in
                guard let strongSelf = self else { return completion(.failure(.cancelled)) }

                // try to fetch data from Network on cache/persistence miss
                let networkCancelable = strongSelf.networkFetch(
                    resource,
                    success: { [weak self ] payload in
                        self?.process(payload,
                                      fromCache: false,
                                      resource: resource,
                                      cancelable: cancelable,
                                      completion: completion) ?? completion(.failure(.cancelled))
                    },
                    cancelled: { completion(.failure(.cancelled)) },
                    failure: { completion(.failure(.network($0))) }) // cache miss, return the network error

                cancelable.add(cancelable: networkCancelable)
            },
            failure: { [weak self] persistenceError in
                guard let strongSelf = self else { return completion(.failure(.cancelled)) }

                // try to fetch data from Network on persistence error
                let networkCancelable = strongSelf.networkFetch(
                    resource,
                    success: { [weak self ] payload in
                        self?.process(payload,
                                      fromCache: false,
                                      resource: resource,
                                      cancelable: cancelable,
                                      completion: completion) ?? completion(.failure(.cancelled))
                    },
                    cancelled: { completion(.failure(.cancelled)) },
                    failure: { completion(.failure(.multiple([persistenceError, $0]))) })

                cancelable.add(cancelable: networkCancelable)
        })

        return cancelable
    }

    // MARK: Processing Methods

    private func process<R>(_ payload: Remote,
                            fromCache: Bool,
                            resource: R,
                            cancelable: CancelableBag,
                            completion: @escaping NetworkStoreCompletionClosure<R.Local, E>)
    where R: NetworkResource & PersistableResource, R.Remote == Remote {

        do {
            // Check if it's cancelled
            guard cancelable.isCancelled == false else {
                completion(.failure(.cancelled))
                return
            }

            // parse the new value from the data
            let value = try parse(payload: payload, for: resource)

            // Check if it's cancelled
            guard cancelable.isCancelled == false else {
                completion(.failure(.cancelled))
                return
            }

            // update persistence with new value
            if !fromCache {
                persistenceStack.setObject(payload, for: resource.persistenceKey) {
                    switch $0 {
                    case .success: break
                    case .failure(let error):
                        print("⚠️ [Alicerce.NetworkPersistableStore]: Failed to persist value for '\(resource)': \(error)")
                    }
                }
            }

            completion(.success(fromCache ? .persistence(value) : .network(value)))

        } catch let error as Parse.Error {
            completion(.failure(.parse(error)))

            // remove any persisted object from the cache if the parsing failed
            if fromCache {
                persistenceStack.removeObject(for: resource.persistenceKey) {
                    switch $0 {
                    case .success: break
                    case .failure(let error):
                        print("⚠️ [Alicerce.NetworkPersistableStore]: Failed to remove value for '\(resource)': \(error)")
                    }
                }
            }
        } catch {
            completion(.failure(.other(error)))
        }
    }

    // MARK: Fetch Methods

    private func networkFetch<R>(_ resource: R,
                                 success: @escaping (Data) -> Void,
                                 cancelled: @escaping () -> Void,
                                 failure: @escaping (Alicerce.Network.Error) -> Void) -> Cancelable
    where R: NetworkResource & PersistableResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response {

        return networkStack.fetch(resource: resource) { result in

            switch result {
            case .success(let data):
                success(data)
            case .failure(.url(let error as NSError))
            where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled:
                cancelled()
            case .failure(let error):
                failure(error)
                }
        }
    }

    private func persistenceFetch<R>(_ resource: R,
                                     cacheHit: @escaping (Data) -> Void,
                                     cacheMiss: @escaping () -> Void,
                                     failure: @escaping (Swift.Error) -> Void)
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

    private func parse<R: NetworkResource & PersistableResource>(payload: Remote, for resource: R) throws -> R.Local
    where R.Remote == Remote {

        guard let performanceMetrics = performanceMetrics else { return try resource.parse(payload) }

        let metadata: PerformanceMetrics.Metadata = [performanceMetrics.modelTypeMetadataKey : "\(R.Local.self)",
                                                     performanceMetrics.payloadSizeMetadataKey : UInt64(payload.count)]

        return try performanceMetrics.measureParse(of: resource, payload: payload, metadata: metadata) {
            try resource.parse(payload)
        }
    }
}
