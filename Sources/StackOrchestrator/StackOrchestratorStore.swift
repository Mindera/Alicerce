import Foundation

public protocol StackOrchestratorStore: AnyObject {

    associatedtype NetworkStack: Alicerce.NetworkStack
    associatedtype PersistenceStack: Alicerce.PersistenceStack where PersistenceStack.Payload == NetworkStack.Remote

    typealias Payload = NetworkStack.Remote
    typealias Response = NetworkStack.Response
    typealias Resource = StackOrchestrator.FetchResource<NetworkStack.Resource, PersistenceStack.Key>
    typealias FetchError = StackOrchestrator.FetchError

    typealias CompletionClosure<T, E: Swift.Error> =
        (Result<StackOrchestrator.FetchValue<T, Response>, E>) -> Void

    typealias FetchCompletionClosure = CompletionClosure<Payload, FetchError>

    var networkStack: NetworkStack { get }
    var persistenceStack: PersistenceStack { get }
    var performanceMetrics: StackOrchestratorPerformanceMetricsTracker? { get }

    @discardableResult
    func fetch(resource: Resource, completion: @escaping FetchCompletionClosure) -> Cancelable

    func clearPersistence(completion: @escaping (Result<Void, PersistenceStack.Error>) -> Void)
}

extension StackOrchestratorStore {

    @discardableResult
    public func fetchAndDecode<T>(
        resource: Resource,
        networkDecoding: ModelDecoding<T, Payload, Response>,
        persistenceDecoding: ModelDecoding<T, Payload, Void>,
        evictOnDecodeFailure: Bool = true,
        completion: @escaping CompletionClosure<T, FetchAndDecodeError>
    ) -> Cancelable {

        let cancelable = CancelableBag()

        cancelable += fetch(resource: resource) { [persistenceStack, performanceMetrics] result in

            switch result {
            case .success(let fetchValue):
                let (payload, decode, decodedValue) = fetchValue.decodingScaffolding(
                    networkDecoding: networkDecoding,
                    persistenceDecoding: persistenceDecoding
                )

                do {
                    let model = try performanceMetrics?.measureDecode(
                        of: resource,
                        payload: payload,
                        decode: decode
                    ) ?? decode()

                    completion(.success(decodedValue(model)))
                } catch {
                    completion(.failure(.decode(error)))

                    guard evictOnDecodeFailure else { return }

                    persistenceStack.removeObject(for: resource.persistenceKey) {

                        switch $0 {
                        case .success:
                            break
                        case .failure(let error):
                            Log.internalLogger.warning(
                                "⚠️ Failed to evict value for '\(resource)' with error: \(error)"
                            )
                        }
                    }
                }

            case .failure(let error):
                completion(.failure(.fetch(error)))
            }
        }

        return cancelable
    }
}

// MARK: - Helpers

private extension StackOrchestrator.FetchValue {

    func decodingScaffolding<U>(
        networkDecoding: ModelDecoding<U, T, Response>,
        persistenceDecoding: ModelDecoding<U, T, Void>
    ) -> (payload: T, decode: () throws -> U, decodedValue: (U) -> StackOrchestrator.FetchValue<U, Response>) {

        switch self {
        case .network(let payload, let response):
            return (payload, { try networkDecoding.decode(payload, response) }, { .network($0, response) })

        case .persistence(let payload):
            // FIXME: Fix using `Void` as the Response when decoding from persistence 🔨🙈
            return (payload, { try persistenceDecoding.decode(payload, ()) }, { .persistence($0) })
        }
    }
}
