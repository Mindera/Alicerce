import Foundation

#if canImport(AlicerceCore)
import AlicerceCore
#endif

public protocol NetworkStack: AnyObject {

    associatedtype Resource
    associatedtype Remote
    associatedtype Response
    associatedtype FetchError: Error

    @discardableResult
    func fetch(resource: Resource, completion: @escaping FetchCompletionClosure) -> Cancelable
}

extension NetworkStack {

    public typealias CompletionClosure<T, E: Error> = (Result<Network.Value<T, Response>, E>) -> Void
    public typealias FetchCompletionClosure = CompletionClosure<Remote, FetchError>
    public typealias FetchResult = Result<Network.Value<Remote, Response>, FetchError>

    @discardableResult
    public func fetchAndDecode<T>(
        resource: Resource,
        decoding: ModelDecoding<T, Remote, Response>,
        completion: @escaping CompletionClosure<T, FetchAndDecodeError>
    ) -> Cancelable {

        fetch(resource: resource) { result in

            switch result {
            case .success(let value):
                do {
                    try completion(.success(value.mapValue(decoding.decode)))
                } catch {
                    completion(.failure(.decode(error)))
                }
            case .failure(let error):
                completion(.failure(.fetch(error)))
            }
        }
    }
}
