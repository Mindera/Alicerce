import Alicerce

class MockURLSessionResourceInterceptor: URLSessionResourceInterceptor {

    var didInvokeInterceptMakeRequestResult:
        ((Result<URLRequest, Error>, @escaping InterceptRequestHandler) -> Cancelable)?

    var didInvokeInterceptScheduledTask: ((Int, URLRequest, Retry.State) -> Void)?

    var didInvokeInterceptSuccessfulTask: ((Int, URLRequest, Data, URLResponse, Retry.State) -> Void)?

    var didInvokeInterceptFailedTask:
        ((Int, URLRequest, Data?, URLResponse?, Network.URLSessionError, Retry.State) -> Retry.Action)?

    @discardableResult
    func interceptMakeRequestResult(
        _ result: Result<URLRequest, Error>,
        handler: @escaping InterceptRequestHandler
    ) -> Cancelable {

        didInvokeInterceptMakeRequestResult?(result, handler) ?? handler(result)
    }

    func interceptScheduledTask(withIdentifier identifier: Int, request: URLRequest, retryState: Retry.State) {

        didInvokeInterceptScheduledTask?(identifier, request, retryState)
    }

    func interceptSuccessfulTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data,
        response: URLResponse,
        retryState: Retry.State
    ) {

        didInvokeInterceptSuccessfulTask?(identifier, request, data, response, retryState)
    }

    // swiftlint:disable:next function_parameter_count
    func interceptFailedTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Network.URLSessionError,
        retryState: Retry.State
    ) -> Retry.Action {

        didInvokeInterceptFailedTask?(identifier, request, data, response, error, retryState) ?? .none
    }
}
