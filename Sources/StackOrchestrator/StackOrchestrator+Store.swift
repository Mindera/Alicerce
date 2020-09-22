import Foundation

extension StackOrchestrator {

    open class Store<NetworkStack, PersistenceStack>: StackOrchestratorStore
    where
        NetworkStack: Alicerce.NetworkStack,
        PersistenceStack: Alicerce.PersistenceStack, PersistenceStack.Payload == NetworkStack.Remote
    {

        public typealias Payload = NetworkStack.Remote
        public typealias Response = NetworkStack.Response

        public typealias PersistenceKey = PersistenceStack.Key

        public typealias Resource = FetchResource<NetworkStack.Resource, PersistenceStack.Key>

        public typealias CompletionClosure<T, Response, E: Swift.Error> = (Result<FetchValue<T, Response>, E>) -> Void
        public typealias FetchCompletionClosure<T> = CompletionClosure<T, Response, FetchError>

        // MARK: - Properties

        public let networkStack: NetworkStack
        public let persistenceStack: PersistenceStack
        public let performanceMetrics: StackOrchestratorPerformanceMetricsTracker?

        // MARK: - Initialization

        public init(
            networkStack: NetworkStack,
            persistenceStack: PersistenceStack,
            performanceMetrics: StackOrchestratorPerformanceMetricsTracker?
        ) {

            self.networkStack = networkStack
            self.persistenceStack = persistenceStack
            self.performanceMetrics = performanceMetrics
        }

        // MARK: - Public Methods

        @discardableResult
        public func fetch(
            resource: Resource,
            completion: @escaping FetchCompletionClosure<Payload>
        ) -> Cancelable {

            // TODO: change the callback structure to allow returning multiple values (+ completion)

            switch resource.strategy {
            case .networkThenPersistence:
                return fetchNetworkFirst(resource: resource, completion: completion)
            case .persistenceThenNetwork:
                return fetchPersistenceFirst(resource: resource, completion: completion)
            }
        }

        public func clearPersistence(completion: @escaping (Result<Void, PersistenceStack.Error>) -> Void) {

            persistenceStack.removeAll(completion: completion)
        }

        // MARK: - Private Methods

        private func fetchNetworkFirst(
            resource: Resource,
            completion: @escaping FetchCompletionClosure<Payload>
        ) -> Cancelable {

            let cancelable = CancelableBag()

            cancelable += networkFetch(
                resource,
                success: { [weak self] value in

                    self?.processNetworkValue(
                        value,
                        resource: resource,
                        cancelable: cancelable,
                        completion: completion
                    )
                    ?? completion(.failure(.cancelled(nil)))
                },
                cancelled: { completion(.failure(.cancelled($0))) },
                failure: { [weak self] networkError in

                    guard let self = self, cancelable.isCancelled == false else {
                        return completion(.failure(.cancelled(networkError)))
                    }

                    // try to fetch data from the Persistence as a fallback
                    self.persistenceFetch(
                        resource,
                        cacheHit: { [weak self] payload in
                            self?.processCachePayload(
                                payload,
                                resource: resource,
                                cancelable: cancelable,
                                completion: completion
                            )
                            ?? completion(.failure(.cancelled(nil)))
                        },
                        cacheMiss: { completion(.failure(.network(networkError))) },
                        failure: { completion(.failure(.multiple([networkError, $0]))) })
                }
            )

            return cancelable
        }

        @discardableResult
        // swiftlint:disable:next function_body_length
        private func fetchPersistenceFirst(
            resource: Resource,
            completion: @escaping FetchCompletionClosure<Payload>
        ) -> Cancelable {

            let cancelable = CancelableBag()

            // try to fetch data from the Persistence
            persistenceFetch(
                resource,
                cacheHit: { [weak self] payload in

                    guard let self = self, cancelable.isCancelled == false else {
                        return completion(.failure(.cancelled(nil)))
                    }

                    // parse the new value from the cached data
                    self.processCachePayload(
                        payload,
                        resource: resource,
                        cancelable: cancelable,
                        completion: completion
                    )

                    // fetch the result from the network and update the cache in the background
                    cancelable += self.networkFetch(
                        resource,
                        success: { [weak self] value in
                            self?.processNetworkValue(
                                value,
                                resource: resource,
                                cancelable: cancelable,
                                completion: { _ in }
                            )
                        },
                        cancelled: { _ in },
                        failure: { error in
                            Log.internalLogger.warning(
                                "⚠️ Failed to fetch update cached value for '\(resource)' with error: \(error)"
                            )
                        }
                    )
                },
                cacheMiss: { [weak self] in

                    guard let self = self, cancelable.isCancelled == false else {
                        return completion(.failure(.cancelled(nil)))
                    }

                    // try to fetch data from Network on cache/persistence miss
                    cancelable += self.networkFetch(
                        resource,
                        success: { [weak self] value in
                            self?.processNetworkValue(
                                value,
                                resource: resource,
                                cancelable: cancelable,
                                completion: completion
                            )
                            ?? completion(.failure(.cancelled(nil)))
                        },
                        cancelled: { completion(.failure(.cancelled($0))) },
                        failure: { completion(.failure(.network($0))) }) // cache miss, return the network error
                },
                failure: { [weak self] persistenceError in

                    guard let self = self, cancelable.isCancelled == false else {
                        return completion(.failure(.cancelled(persistenceError)))
                    }

                    // try to fetch data from Network on persistence error
                    cancelable += self.networkFetch(
                        resource,
                        success: { [weak self] payload in
                            self?.processNetworkValue(
                                payload,
                                resource: resource,
                                cancelable: cancelable,
                                completion: completion
                            )
                            ?? completion(.failure(.cancelled(persistenceError)))
                        },
                        cancelled: { completion(.failure(.cancelled($0))) },
                        failure: { completion(.failure(.multiple([persistenceError, $0]))) })
                }
            )

            return cancelable
        }

        // MARK: Fetch Methods

        private func networkFetch(
            _ resource: Resource,
            success: @escaping (Network.Value<Payload, Response>) -> Void,
            cancelled: @escaping (Error) -> Void,
            failure: @escaping (Error) -> Void
        ) -> Cancelable {

            let cancelable = CancelableBag()

            cancelable += networkStack.fetch(resource: resource.networkResource) { result in

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

        private func persistenceFetch(
            _ resource: Resource,
            cacheHit: @escaping (Payload) -> Void,
            cacheMiss: @escaping () -> Void,
            failure: @escaping (Error) -> Void
        ) {

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

        // MARK: Processing Methods

        private func processNetworkValue(
            _ value: Network.Value<Payload, Response>,
            resource: Resource,
            cancelable: CancelableBag,
            completion: @escaping FetchCompletionClosure<Payload>
        ) {

            guard cancelable.isCancelled == false else { return completion(.failure(.cancelled(nil))) }

            completion(.success(.network(value.value, value.response)))

            // update persistence stack after returning value
            persistenceStack.setObject(value.value, for: resource.persistenceKey) {
                switch $0 {
                case .success: break
                case .failure(let error):
                    Log.internalLogger.warning("⚠️ Failed to persist value for '\(resource)' with error: \(error)")
                }
            }
        }

        private func processCachePayload(
            _ payload: Payload,
            resource: Resource,
            cancelable: CancelableBag,
            completion: @escaping FetchCompletionClosure<Payload>
        ) {

            guard cancelable.isCancelled == false else { return completion(.failure(.cancelled(nil))) }

            completion(.success(.persistence(payload)))
        }
    }
}
