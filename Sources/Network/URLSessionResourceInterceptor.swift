import Foundation

public protocol URLSessionResourceInterceptor {

    /// A resource's make request handler closure, invoked when the request generation finishes.
    typealias InterceptRequestHandler = (Result<URLRequest, Error>) -> Cancelable

    @discardableResult
    func interceptMakeRequestResult(
        _ result: Result<URLRequest, Error>,
        handler: @escaping InterceptRequestHandler
    ) -> Cancelable

    func interceptScheduledTask(withIdentifier identifier: Int, request: URLRequest, retryState: Retry.State)

    func interceptSuccessfulTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data,
        response: URLResponse,
        retryState: Retry.State
    )

    // swiftlint:disable:next function_parameter_count
    func interceptFailedTask(
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

        return .none
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

        return evaluateFailedRequest(request, data: data, response: response, error: error, retryState: retryState)
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

        return shouldRetry(with: error, state: retryState, metadata: (request, data, response))
    }
}
