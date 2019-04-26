import Foundation
import Result

public enum NetworkStoreValue<T> {
    case network(T, URLResponse)
    case persistence(T)

    public var value: T {
        switch self {
        case .network(let value, _): return value
        case .persistence(let value): return value
        }
    }
}

public typealias NetworkStoreCompletionClosure<T, E: Error> = (Result<NetworkStoreValue<T>, E>) -> Void

public protocol NetworkStore {

    associatedtype Remote
    associatedtype Request
    associatedtype Response
    associatedtype E: Error

    typealias FetchResource =
        NetworkStack.FetchResource & DecodableResource & PersistableResource & NetworkStoreStrategyFetchResource

    @discardableResult
    func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Internal, E>) -> Cancelable
    where R: FetchResource,
          R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response
}

public extension NetworkStore
where Self: NetworkStack, E == NetworkPersistableStoreError {

    @discardableResult
    func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Internal, E>) -> Cancelable
    where R: NetworkStore.FetchResource,
          R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

        let cancelable = CancelableBag()

        cancelable += fetch(resource: resource) { (result: Result<Network.Value<R.External>, Network.Error>) in

            switch result {
            case .success(let response):
                do {
                    completion(.success(.network(try resource.decode(response.value), response.response)))
                } catch let error as Parse.Error {
                    completion(.failure(.parse(error)))
                } catch {
                    completion(.failure(.other(error)))
                }
            case .failure(let error) where cancelable.isCancelled:
                completion(.failure(.cancelled(error)))
            case .failure(let error):
                completion(.failure(.network(error)))
            }
        }

        return cancelable
    }
}
