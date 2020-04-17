import Foundation

public enum NetworkStackError<FetchError: Error>: Error {
    case fetch(FetchError)
    case decode(Error)
}

public protocol NetworkStack: AnyObject {

    associatedtype Resource
    associatedtype Remote
    associatedtype Response
    associatedtype FetchError: Error

    typealias CompletionClosure<T, E: Swift.Error> = (Result<Network.Value<T, Response>, E>) -> Void

    typealias FetchCompletionClosure = CompletionClosure<Remote, FetchError>

    func fetch(resource: Resource, completion: @escaping FetchCompletionClosure) -> Cancelable
}

extension NetworkStack {

    public func fetchAndDecode<T>(
        resource: Resource,
        decoding: Network.ModelDecoding<T, Remote, Response>,
        completion: @escaping CompletionClosure<T, NetworkStackError<FetchError>>
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
