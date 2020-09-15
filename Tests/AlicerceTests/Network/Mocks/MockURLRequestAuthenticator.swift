import Foundation
@testable import Alicerce

final class MockURLRequestAuthenticator: URLRequestAuthenticator {

    var mockAuthenticateRequest: (URLRequest, @escaping AuthenticationHandler) -> Cancelable = { $1(.success($0)) }
    var mockEvaluateFailedRequest: (URLRequest, Data?, URLResponse?, Error, Retry.State) -> Retry.Action =
        { _, _, _, _, _ in .none }

    @discardableResult
    func authenticateRequest(_ request: URLRequest, handler: @escaping AuthenticationHandler) -> Cancelable {

        mockAuthenticateRequest(request, handler)
    }

    func evaluateFailedRequest(
        _ request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Error,
        retryState: Retry.State
    ) -> Retry.Action {

        mockEvaluateFailedRequest(request, data, response, error, retryState)
    }
}

extension MockURLRequestAuthenticator: URLSessionResourceInterceptor {}
