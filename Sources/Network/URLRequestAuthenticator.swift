import Foundation

// A type representing a request authenticator.
public protocol URLRequestAuthenticator: AnyObject {

    /// The authenticator's authentication handler closure, invoked when a request's authentication finishes.
    typealias AuthenticationHandler = (Result<URLRequest, Error>) -> Cancelable

    /// Authenticates a request.
    ///
    /// - Important: The cancelable returned by the `handler` closure *when called asynchronously* should be added
    /// as a child of the cancelable returned by this method, so that the async work gets chained and can be cancelled.
    ///
    /// - Parameters:
    ///   - request: The request to authenticate.
    ///   - handler: The closure to handle the request authentication's result (i.e. either the authenticated request
    /// or an error).
    ///
    /// - Returns: A cancelable to cancel the operation.
    @discardableResult
    func authenticateRequest(_ request: URLRequest, handler: @escaping AuthenticationHandler) -> Cancelable

    /// Evaluates failed requests and determines which action to take from an authentication perspective.
    /// - Parameters:
    ///   - request: The failed request.
    ///   - response: The failed request's response.
    ///   - payload: The failed request's payload.
    ///   - error: The failed request's error.
    ///   - retryState: The retry state, containing:
    ///     + errors that have occured so far (i.e. have resulted in a previous retry), excluding the current error.
    ///     + the total amount of delay that has been used on retries.
    ///
    /// - Returns: The retry action to apply to the operation.
    func evaluateFailedRequest(
        _ request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Error,
        retryState: Retry.State
    ) -> Retry.Action
}
