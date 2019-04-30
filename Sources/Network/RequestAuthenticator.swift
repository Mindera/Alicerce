import Foundation

// A type representing a request authenticator.
public protocol RequestAuthenticator: AnyObject {

    /// A type that represents a network request.
    associatedtype Request

    /// A type that represents a request authentication error.
    associatedtype Error: Swift.Error

    /// The authenticator's authentication handler closure, invoked when a request's authentication finishes.
    typealias AuthenticationHandler = (Result<Request, Error>) -> Cancelable

    /// Authenticates a request.
    ///
    /// - Important: The cancelable returned by the `handler` closure *when called asynchronously* should be added
    /// as a child of the cancelable returned by this method, so that the async work gets chained and can be cancelled.
    ///
    /// - Parameters:
    ///   - request: The request to authenticate.
    ///   - handler: The closure to handle the request authentication's result (i.e. either the authenticated request
    /// or an error).
    /// - Returns: A cancelable to cancel the operation.
    @discardableResult
    func authenticate(_ request: Request, handler: @escaping AuthenticationHandler) -> Cancelable
}

/// A type representing a request authenticator that provides a retry policy rule (to handle authentication errors).
public protocol RetryableRequestAuthenticator: RequestAuthenticator {

    /// A type that represents a resource's remote type.
    associatedtype Remote

    /// A type that represent a network response.
    associatedtype Response

    /// The authenticator's retry metadata.
    typealias RetryMetadata = (request: Request, payload: Remote?, response: Response?)

    /// The authenticator's specialized retry policy.
    typealias RetryPolicy = Retry.Policy<RetryMetadata>

    /// The retry policy used to evaluate which action to take when an error occurs.
    var retryPolicyRule: RetryPolicy.Rule { get }
}

// A type representing a request authenticator specialized to authenticate `URLRequest`'s.
public protocol URLRequestAuthenticator: RequestAuthenticator
where Request == URLRequest {}

/// A type representing a request authenticator specialized to authenticate `URLRequest`'s that provides a retry policy
/// rule (to handle authentication errors) specialized for `Data` remote type, `URLRequest`'s and `URLResponse`'s.
public protocol RetryableURLRequestAuthenticator: RetryableRequestAuthenticator
where Remote == Data, Request == URLRequest, Response == URLResponse {}
