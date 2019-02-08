import Foundation
import Result

/// A type representing a resource that is fetched from the network.
public protocol NetworkResource: Resource {

    /// A type representing the network request.
    associatedtype Request

    /// The resource's make request handler closure, invoked when the request generation finishes.
    typealias MakeRequestHandler = (Result<Request, AnyError>) -> Cancelable

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

    /// An empty instance of the resource's remote type (e.g. used for returning a value on 204's HTTP status codes).
    static var empty: Remote { get }
}
