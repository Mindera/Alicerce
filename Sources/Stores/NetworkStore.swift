import Foundation

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
