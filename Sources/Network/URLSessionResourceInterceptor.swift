import Foundation

/// A type representing a resource interceptor.
public protocol URLSessionResourceInterceptor {

    /// An interceptor's intercept request handler closure, invoked when the make request interception finishes.
    typealias InterceptRequestHandler = (Result<URLRequest, Error>) -> Cancelable

    /// Intercepts a request being made before being scheduled, either the base request from the
    /// `URLSessionResource.baseRequestMaking.make` closure (initial), or from the previous interceptor's
    /// `interceptMakeRequestResult` (subsequent).
    ///
    /// - Parameters:
    ///   - result: The current request result, either the base or already intercepted by previous chain elements.
    ///   - handler: The closure to invoke with the intercepted request result (modified or not).
    @discardableResult
    func interceptMakeRequestResult(
        _ result: Result<URLRequest, Error>,
        handler: @escaping InterceptRequestHandler
    ) -> Cancelable

    /// Intercepts a `URLSessionDataTask` scheduled by the `URLSessionNetworkStack` for a particular `Resource`'s
    /// request.
    ///
    /// - Parameters:
    ///   - identifier: The task's identifier, obtained from `URLSessionTask.taskIdentifier`.
    ///   - request: The current request being scheduled for this resource.
    ///   - retryState: The current retry state of the resource.
    func interceptScheduledTask(withIdentifier identifier: Int, request: URLRequest, retryState: Retry.State)

    /// Intercepts a successful `URLSessionDataTask` for a particular `Resource`'s request.
    ///
    /// - Parameters:
    ///   - identifier: The task's identifier, obtained from `URLSessionTask.taskIdentifier`.
    ///   - request: The current request being scheduled for this resource.
    ///   - data: The network payload returned by the session task.
    ///   - response: The response returned by the session task.
    ///   - retryState: The current retry state of the resource.
    func interceptSuccessfulTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data,
        response: URLResponse,
        retryState: Retry.State
    )

    /// Intercepts a failed `URLSessionDataTask` for a particular `Resource`'s request.
    ///
    /// - Parameters:
    ///   - identifier: The task's identifier, obtained from `URLSessionTask.taskIdentifier`.
    ///   - request: The current request being scheduled for this resource.
    ///   - data: The network payload returned by the session task.
    ///   - response: The response returned by the session task.
    ///   - error: The error which caused the oepration to fail.
    ///   - retryState: The current retry state of the resource.
    ///
    /// - Returns: The retry action to apply to the operation.
    func interceptFailedTask( // swiftlint:disable:this function_parameter_count
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Network.URLSessionError,
        retryState: Retry.State
    ) -> Retry.Action
}

// MARK: - Default implementation

extension URLSessionResourceInterceptor {

    @discardableResult
    public func interceptMakeRequestResult(
        _ result: Result<URLRequest, Error>,
        handler: @escaping InterceptRequestHandler
    ) -> Cancelable {

        return handler(result)
    }

    public func interceptScheduledTask(withIdentifier identifier: Int, request: URLRequest, retryState: Retry.State) {}

    public func interceptSuccessfulTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data,
        response: URLResponse,
        retryState: Retry.State
    ) {}

    // swiftlint:disable:next function_parameter_count
    public func interceptFailedTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Network.URLSessionError,
        retryState: Retry.State
    ) -> Retry.Action {

        .none
    }
}

// MARK: - URLRequestAuthenticator default implementation

extension URLSessionResourceInterceptor where Self: URLRequestAuthenticator {

    public func interceptMakeRequestResult(
        _ result: Result<URLRequest, Error>,
        handler: @escaping InterceptRequestHandler
    ) -> Cancelable {

        switch result {
        case .success(let newRequest):
            return authenticateRequest(newRequest) { handler($0.mapError { $0 as Error }) }
        case .failure(let error):
            return handler(.failure(error))
        }
    }

    // swiftlint:disable:next function_parameter_count
    public func interceptFailedTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Network.URLSessionError,
        retryState: Retry.State
    ) -> Retry.Action {

        evaluateFailedRequest(request, data: data, response: response, error: error, retryState: retryState)
    }
}

// MARK: - Network.URLSessionRetryPolicy default implementation

extension Network.URLSessionRetryPolicy: URLSessionResourceInterceptor {

    // swiftlint:disable:next function_parameter_count
    public func interceptFailedTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Network.URLSessionError,
        retryState: Retry.State
    ) -> Retry.Action {

        shouldRetry(with: error, state: retryState, metadata: (request, data, response))
    }
}
