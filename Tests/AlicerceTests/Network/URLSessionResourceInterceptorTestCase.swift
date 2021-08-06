import XCTest
@testable import Alicerce

class URLSessionResourceInterceptorTestCase: XCTestCase {

    let request = URLRequest(url: URL(string: "www.mindera.com")!) // swiftlint:disable:this force_unwrapping

    // MARK: - Default implementation

    func testDefaultInterceptMakeRequestResult_WithSuccessResult_ShouldInvokeHandlerAndPropagateResult() {

        let result = Result<URLRequest, Error>.success(request)
        let mockCancelable = MockCancelable()

        let cancelable = DummyURLSessionResourceInterceptor().interceptMakeRequestResult(result) { r in
            XCTAssertDumpsEqual(r, result)
            return mockCancelable
        }

        XCTAssertIdentical(cancelable, mockCancelable)
    }

    func testDefaultInterceptMakeRequestResult_WithFailureResult_ShouldInvokeHandlerAndPropagateResult() {

        enum MockError: Error { case 💩 }

        let result = Result<URLRequest, Error>.failure(MockError.💩)
        let mockCancelable = MockCancelable()

        let cancelable = DummyURLSessionResourceInterceptor().interceptMakeRequestResult(result) { r in
            XCTAssertDumpsEqual(r, result)
            return mockCancelable
        }

        XCTAssertIdentical(cancelable, mockCancelable)
    }

    func testDefaultInterceptFailedTask_ShouldReturnNoneAction() {

        let action = DummyURLSessionResourceInterceptor().interceptFailedTask(
            withIdentifier: 1337,
            request: request,
            data: nil,
            response: nil,
            error: .cancelled,
            retryState: .empty
        )

        XCTAssertDumpsEqual(action, .none)
    }

    // MARK: - URLRequestAuthenticator default implementation

    func testAuthenticatorInterceptMakeRequestResult_WithSuccessResultAndAuthenticationSuccess_ShouldAuthenticateRequestAndPropagateResult() {

        let authenticator = MockURLRequestAuthenticator()

        let result = Result<URLRequest, Error>.success(request)
        let mockCancelable = MockCancelable()

        var authenticatedRequest = request
        authenticatedRequest.allHTTPHeaderFields = ["🔒": "🔑"]

        authenticator.mockAuthenticateRequest = { request, completion in
            XCTAssertEqual(request, self.request)
            return completion(.success(authenticatedRequest))
        }

        let cancelable = authenticator.interceptMakeRequestResult(result) { r in
            XCTAssertDumpsEqual(r, .success(authenticatedRequest))
            return mockCancelable
        }

        XCTAssertIdentical(cancelable, mockCancelable)
    }

    func testAuthenticatorInterceptMakeRequestResult_WithFailureResult_ShouldInvokeHandlerAndPropagateResult() {

        enum MockError: Error { case 💩 }

        let result = Result<URLRequest, Error>.failure(MockError.💩)
        let mockCancelable = MockCancelable()

        let cancelable = MockURLRequestAuthenticator().interceptMakeRequestResult(result) { r in
            XCTAssertDumpsEqual(r, result)
            return mockCancelable
        }

        XCTAssertIdentical(cancelable, mockCancelable)
    }

    func testAuthenticatorInterceptFailedTask_ShouldReturnAuthenticatorAction() {

        let authenticator = MockURLRequestAuthenticator()

        let mockData = Data("🏗".utf8)
        let mockResponse = URLResponse()
        let mockError = Network.URLSessionError.badResponse(mockResponse)
        let mockRetryState = Retry.State(errors: [], totalDelay: 1.337)

        authenticator.mockEvaluateFailedRequest = { request, data, response, error, state in

            XCTAssertEqual(request, self.request)
            XCTAssertEqual(data, mockData)
            XCTAssertEqual(response, mockResponse)
            XCTAssertDumpsEqual(error, mockError)
            XCTAssertDumpsEqual(state, mockRetryState)

            return .retryAfter(1337)
        }

        let action = authenticator.interceptFailedTask(
            withIdentifier: 1337,
            request: request,
            data: mockData,
            response: mockResponse,
            error: mockError,
            retryState: mockRetryState
        )

        XCTAssertDumpsEqual(action, .retryAfter(1337))
    }

    // MARK: - Network.URLSessionRetryPolicy default implementation

    func testRetryPolicyInterceptFailedTask_ShouldReturnPolicyAction() {

        let mockData = Data("🏗".utf8)
        let mockResponse = URLResponse()
        let mockError = Network.URLSessionError.badResponse(mockResponse)
        let mockRetryState = Retry.State(errors: [], totalDelay: 1.337)

        let rule: Network.URLSessionRetryPolicy.Rule = { error, state, metadata in

            let (request, data, response) = metadata

            XCTAssertEqual(request, self.request)
            XCTAssertEqual(data, mockData)
            XCTAssertEqual(response, mockResponse)
            XCTAssertDumpsEqual(error, mockError)
            XCTAssertDumpsEqual(state, mockRetryState)

            return .retryAfter(1337)
        }

        let policy = Network.URLSessionRetryPolicy.custom(rule)

        let action = policy.interceptFailedTask(
            withIdentifier: 1337,
            request: request,
            data: mockData,
            response: mockResponse,
            error: mockError,
            retryState: mockRetryState
        )

        XCTAssertDumpsEqual(action, .retryAfter(1337))
    }
}

private final class DummyURLSessionResourceInterceptor: URLSessionResourceInterceptor {}
