import Foundation

/// A type representing a resource that is fetched from or sent to the network.
public protocol NetworkResource: RequestResource {

    /// A type representing the network response.
    associatedtype Response

    /// A resource's make request handler closure, invoked when the request generation finishes.
    typealias MakeRequestHandler = (Result<Request, Error>) -> Cancelable

    /// Generates a new request to fetch the resource (to be scheduled by the network client).
    ///
    /// - Important: The cancelable returned by the `handler` closure *when called asynchronously* should be added
    /// as a child of the cancelable returned by this method, so that the async work gets chained and can be cancelled.
    ///
    /// - Parameter completion: The closure to handle the request generation's result (i.e. either the new request or
    /// an error).
    /// - Returns: A cancelable to cancel the operation.
    @discardableResult
    func makeRequest(_ handler: @escaping MakeRequestHandler) -> Cancelable
}

public extension NetworkResource where Self: BaseRequestResource {

    @discardableResult
    func makeRequest(_ handler: @escaping MakeRequestHandler) -> Cancelable {

        return handler(.success(baseRequest))
    }
}

public extension NetworkResource where Self: AuthenticatedRequestResource & BaseRequestResource {

    @discardableResult
    func makeRequest(_ handler: @escaping MakeRequestHandler) -> Cancelable {

        return authenticator.authenticate(baseRequest) { handler($0.mapError { $0 as Error }) }
    }
}
