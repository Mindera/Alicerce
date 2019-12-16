import Foundation

public enum NetworkStoreValue<T, Response> {
    case network(T, Response)
    case persistence(T)

    public var value: T {
        switch self {
        case .network(let value, _): return value
        case .persistence(let value): return value
        }
    }
}

public typealias NetworkStoreFetchCompletionClosure<T, Response, E: Error> =
    (Result<NetworkStoreValue<T, Response>, E>) -> Void

public protocol NetworkStore {

    associatedtype Remote
    associatedtype Request
    associatedtype Response
    associatedtype StoreError: Swift.Error

    typealias FetchResource =
        NetworkStack.FetchResource & DecodableResource & PersistableResource & NetworkStoreStrategyFetchResource

    @discardableResult
    func fetch<R>(
        resource: R,
        completion: @escaping NetworkStoreFetchCompletionClosure<R.Internal, Response, StoreError>
    ) -> Cancelable
    where R: FetchResource,
          R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response
}
