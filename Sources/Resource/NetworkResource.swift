import Foundation
import Result

/// A type representing a resource that is fetched from the network.
public protocol NetworkResource: Resource {

    /// A type representing the network request.
    associatedtype Request

    /// A type representing the network response.
    associatedtype Response

    /// A type representing an API error.
    associatedtype APIError: Swift.Error

    /// A resource's parse API error closure, invoked when a request fails with a protocol error in an attempt to
    /// extract a custom API error.
    typealias ParseAPIErrorClosure = (Remote?, Response) -> APIError?

    /// A resource's make request handler closure, invoked when the request generation finishes.
    typealias MakeRequestHandler = (Result<Request, AnyError>) -> Cancelable

    /// The resource's parse API error closure, invoked when a request fails with a protocol error in an attempt to
    /// extract a custom API error.
    var parseAPIError: ParseAPIErrorClosure { get }

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
