import Foundation
import Result

public enum NetworkPersistableStoreError: Swift.Error {
    case network(Network.Error)
    case parse(Parse.Error)
    case persistence(Persistence.Error)
    case cancelled
    case other(Swift.Error)
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

    @discardableResult
    public func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>) -> Cancelable
    where R: NetworkResource & PersistableResource & StrategyFetchResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response
    {

        switch resource.strategy {
        case .networkThenPersistence: return fetchNetworkFirst(resource: resource, completion: completion)
        case .persistenceThenNetwork: return fetchPersistenceFirst(resource: resource, completion: completion)
        }
    }

    private func fetchNetworkFirst<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>)
    -> Cancelable
    where R: NetworkResource & PersistableResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response {

        let cancelable = CancelableBag()

        // 1st - Try to fetch from the Network
        let networkCancelable = getNetworkPayload(resource) { [weak self] result in

            switch result {
            case let .failure(error):

                // Check if it's cancelled
                guard cancelable.isCancelled == false else {
                    completion(.failure(error))
                    return
                }
                
                // The system failed to retrieve the data from the network, so we should check if the data is already on disk

                // 2nd - Fetch data from the Persistence
                self?.getPersistedPayload(for: resource) { [weak self] payload in

                    // If we don't have on disk return the network error
                    guard let payload = payload else {
                        completion(.failure(error))
                        return
                    }

                    // parse the new value from the data
                    self?.process(payload,
                                  fromCache: true,
                                  resource: resource,
                                  cancelable: cancelable,
                                  completion: completion)
                }

            case let .success(payload):

                // parse the new value from the data
                self?.process(payload,
                              fromCache: false,
                              resource: resource,
                              cancelable: cancelable,
                              completion: completion)

            }
        }

        cancelable.add(cancelable: networkCancelable)

        return cancelable
    }

    @discardableResult
    private func fetchPersistenceFirst<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>)
    -> Cancelable
    where R: NetworkResource & PersistableResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response {

            let cancelable = CancelableBag()

            // 1st - Fetch data from the Persistence
            getPersistedPayload(for: resource) { [weak self] payload in
                guard let strongSelf = self else { return completion(.failure(.cancelled)) }

                // If we have data we don't need to go to the network
                if let payload = payload {

                    // parse the new value from the data
                    strongSelf.process(payload,
                                       fromCache: true,
                                       resource: resource,
                                       cancelable: cancelable,
                                       completion: completion)

                } else {

                    // 2nd - Try to fetch Data from Network
                    let networkCancelable = strongSelf.getNetworkPayload(resource) { result in

                        switch result {
                        case let .success(payload):
                            // parse the new value from the data
                            strongSelf.process(payload,
                                               fromCache: false,
                                               resource: resource,
                                               cancelable: cancelable,
                                               completion: completion)
                        case let .failure(error):
                            completion(.failure(error))
                        }
                    }

                    cancelable.add(cancelable: networkCancelable)
                }
            }

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
                self.persist(payload, for: resource)
            }

            completion(.success(fromCache ? .persistence(value) : .network(value)))

        } catch let error as Parse.Error {
            completion(.failure(.parse(error)))
        } catch {
            completion(.failure(.other(error)))
        }
    }

    // MARK: Network Methods

    private func getNetworkPayload<R>(_ resource: R, completion: @escaping (Result<Remote, E>) -> Void)
    -> Cancelable
    where R: NetworkResource & PersistableResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response {

        return networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(data):
                completion(.success(data))

            case let .failure(error):
                switch error {
                case let Alicerce.Network.Error.url(error as NSError) where error.domain == NSURLErrorDomain
                    && error.code == NSURLErrorCancelled:
                    completion(.failure(.cancelled))
                default:
                    completion(.failure(.network(error)))
                }
            }
        }
    }

    // MARK: Persistence Methods

    private func getPersistedPayload<R: PersistableResource>(for resource: R, completion: @escaping (Remote?) -> Void) {

        persistenceStack.object(for: resource.persistenceKey) { (inner: () throws -> Remote) -> Void in
            do {
                let payload = try inner()
                return completion(payload)
            } catch Alicerce.Persistence.Error.noObjectForKey {
                // cache/persistence miss
            } catch {
                print("⚠️: Failed to get persisted value for resource \"\(resource)\"! Error: \(error). Fetching...")
            }
            completion(nil)
        }
    }

    private func persist<R: PersistableResource>(_ payload: Remote, for resource: R) {

        persistenceStack.setObject(payload, for: resource.persistenceKey) { (inner: () throws -> Void) -> Void in
            do {
                try inner()
            } catch {
                print("⚠️: Failed to persist value for resource \"\(resource)\"! Error:\(error)")
            }
        }
    }

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
