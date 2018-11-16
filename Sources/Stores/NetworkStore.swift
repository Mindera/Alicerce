import Foundation
import Result

public enum NetworkStoreValue<T> {
    case network(T)
    case persistence(T)

    public var value: T {
        switch self {
        case .network(let value): return value
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

    @discardableResult
    func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>) -> Cancelable
    where R: NetworkResource & PersistableResource & StrategyFetchResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response
}

public extension NetworkStore
where Self: NetworkStack, Self.Remote == Remote, Self.Request == Request, Self.Response == Response,
      E == NetworkPersistableStoreError {

    @discardableResult
    public func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>) -> Cancelable
    where R: NetworkResource & PersistableResource & StrategyFetchResource & RetryableResource,
          R.Remote == Remote, R.Request == Request, R.Response == Response {

        let cancelable = CancelableBag()

        cancelable += fetch(resource: resource) { (result: Result<R.Remote, Network.Error>) in

            switch result {
            case .success(let remote):
                do {
                    completion(.success(.network(try resource.parse(remote))))
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
