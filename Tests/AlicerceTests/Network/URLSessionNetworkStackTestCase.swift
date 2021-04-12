import XCTest
@testable import Alicerce

final class URLSessionNetworkStackTestCase: XCTestCase {

    private typealias RetryPolicy = Network.URLSessionRetryPolicy

    private var authenticationChallengeHandler: MockAuthenticationChallengeHandler!
    private var retryQueue: DispatchQueue!

    private var networkStack: Network.URLSessionNetworkStack!
    private var mockSession: MockURLSession!

    private var resource: Network.URLSessionResource!

    private let successResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                                  statusCode: 200,
                                                  httpVersion: nil,
                                                  headerFields: nil)!
    private let failureResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                                  statusCode: 500,
                                                  httpVersion: nil,
                                                  headerFields: nil)!

    fileprivate let expectationTimeout: TimeInterval = 5

    override func setUp() {
        super.setUp()

        authenticationChallengeHandler = MockAuthenticationChallengeHandler()
        retryQueue = DispatchQueue(label: "network-stack.retry-queue")
        networkStack = Network.URLSessionNetworkStack(
            authenticationChallengeHandler: authenticationChallengeHandler,
            retryQueue: retryQueue
        )
        mockSession = MockURLSession(delegate: networkStack)

        networkStack.session = mockSession

        resource = .mock()
    }

    override func tearDown() {

        authenticationChallengeHandler = nil
        retryQueue = nil
        networkStack = nil
        mockSession = nil

        resource = nil

        super.tearDown()
    }

    // MARK: - finishFetchesAndInvalidateSession

    func testFetchesTasksAndInvalidateSession_WithSetSession_ShouldCallFinishTasksAndInvalidateOnTheSession() {
        let expectation = self.expectation(description: "testFinishTasksAndInvalidateSession")
        defer { waitForExpectations(timeout: expectationTimeout) }

        networkStack = Network.URLSessionNetworkStack(retryQueue: retryQueue)
        mockSession = MockURLSession(delegate: networkStack)

        networkStack.session = mockSession

        mockSession.didInvokeFinishTasksAndInvalidate = { expectation.fulfill() }

        networkStack.finishFetchesAndInvalidateSession()
    }

    // MARK: - fetch (success)

    func testFetch_WithSuccessfulResponse_ShouldCallCompletionClosureWithData() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(response):
                XCTAssertEqual(response.value, mockData)
                XCTAssertEqual(response.response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithSuccessfull204StatusCodeResponse_ShouldCallCompletionClosureWithEmptyData() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                           statusCode: 204,
                                           httpVersion: nil,
                                           headerFields: nil)!

        mockSession.mockDataTaskData = nil
        mockSession.mockURLResponse = mockResponse

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(response):
                XCTAssertEqual(response.value, Data())
                XCTAssertEqual(response.response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WhenSuccessful205StatusCodeResponse_ShouldCallCompletionClosureWithEmptyData() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                           statusCode: 205,
                                           httpVersion: nil,
                                           headerFields: nil)!

        mockSession.mockDataTaskData = nil
        mockSession.mockURLResponse = mockResponse

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(response):
                XCTAssertEqual(response.value, Data())
                XCTAssertEqual(response.response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithSuccessfulMakeRequest_ShouldPerformRequest() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "makeRequest")
        let expectation4 = self.expectation(description: "session dataTask")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)

        resource = .mock(
            baseRequestMaking: .init { handler in
                expectation2.fulfill()
                return handler(.success(mockRequest))
            }
        )

        mockSession.mockDataTaskResumeInvokedClosure = {
            XCTAssertEqual($0, mockRequest)
            expectation4.fulfill()
        }

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(response):
                XCTAssertEqual(response.value, mockData)
                XCTAssertEqual(response.response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithFailingMakeRequest_ShouldNotPerformRequest() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "makeRequest")
        defer { waitForExpectations(timeout: expectationTimeout) }

        resource = .mock(
            baseRequestMaking: .init { handler in
                expectation2.fulfill()
                return handler(.failure(MockError.🧨))
            }
        )

        mockSession.mockDataTaskResumeInvokedClosure = { _ in XCTFail("unexpected dataTask resume!") }

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .failure(.noRequest(MockError.🧨)):
                break
            case .failure(let error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            case let .success(response):
                XCTFail("🔥 received unexpected response 👉 \(response) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchCancel_ShouldCancelTask() {
        let expectation = self.expectation(description: "testFetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout) }

        mockSession.mockDataTaskData = "🎉".data(using: .utf8)
        mockSession.mockURLResponse = successResponse
        mockSession.mockDataTaskCancelInvokedClosure = {
            expectation.fulfill()
        }

        let cancelable = networkStack.fetch(resource: resource) { _ in }

        cancelable.cancel()
    }

    // MARK: with retry policy

    func testFetchWithRetryPolicy_WhenPolicyReturnsRetry_ShouldFetchAgain() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = URLError(.badURL)

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetriesBeforeSuccess = 2
        var retryCount = 0

        let expectedError = Network.URLSessionError.url(mockError)

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        let mockRule: RetryPolicy.Rule = { error, state, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, expectedError)
            XCTAssertEqual(state.errors.count, retryCount)
            state.errors.forEach { XCTAssertDumpsEqual($0, expectedError) }
            XCTAssertEqual(state.totalDelay, 0)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            // return success after 2nd retry
            if retryCount == numRetriesBeforeSuccess {
                self.mockSession.mockDataTaskError = nil
            }

            return .retry
        }

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [RetryPolicy.custom(mockRule)]
        )

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(response):
                XCTAssertEqual(response.value, mockData)
                XCTAssertEqual(response.response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchWithRetryPolicy_WhenPolicyReturnsRetryAfter_ShouldFetchAgain() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = URLError(.badURL)

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetriesBeforeSuccess = 3
        var retryCount = 0
        let baseRetryDelay: Retry.Delay = 0.01

        let expectedError = Network.URLSessionError.url(mockError)

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        let mockRule: RetryPolicy.Rule = { error, state, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, expectedError)
            XCTAssertEqual(state.errors.count, retryCount)
            state.errors.forEach { XCTAssertDumpsEqual($0, expectedError) }
            XCTAssertEqual(state.totalDelay, baseRetryDelay * Double(retryCount))
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            // return success after 2nd retry
            if retryCount == numRetriesBeforeSuccess {
                self.mockSession.mockDataTaskError = nil
            }

            return .retryAfter(baseRetryDelay)
        }

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [RetryPolicy.custom(mockRule)]
        )

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(response):
                XCTAssertEqual(response.value, mockData)
                XCTAssertEqual(response.response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchWithRetryPolicy_WhenPolicyReturnsRetryAfterWithZeroDelay_ShouldFetchAgain() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = URLError(.badURL)

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetriesBeforeSuccess = 3
        var retryCount = 0
        let retryDelay: Retry.Delay = 0

        let expectedError = Network.URLSessionError.url(mockError)

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        let mockRule: RetryPolicy.Rule = { error, state, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, expectedError)
            XCTAssertEqual(state.errors.count, retryCount)
            state.errors.forEach { XCTAssertDumpsEqual($0, expectedError) }
            XCTAssertEqual(state.totalDelay, 0)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            // return success after 2nd retry
            if retryCount == numRetriesBeforeSuccess {
                self.mockSession.mockDataTaskError = nil
            }

            return .retryAfter(retryDelay)
        }

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [RetryPolicy.custom(mockRule)]
        )

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(response):
                XCTAssertEqual(response.value, mockData)
                XCTAssertEqual(response.response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchWithRetryPolicy_WhenPolicyReturnsRetryAfterWithNegativeDelay_ShouldFetchAgain() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = URLError(.badURL)

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetriesBeforeSuccess = 3
        var retryCount = 0
        let retryDelay: Retry.Delay = -1.337

        let expectedError = Network.URLSessionError.url(mockError)

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        let mockRule: RetryPolicy.Rule = { error, state, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, expectedError)
            XCTAssertEqual(state.errors.count, retryCount)
            state.errors.forEach { XCTAssertDumpsEqual($0, expectedError) }
            XCTAssertEqual(state.totalDelay, 0)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            // return success after 2nd retry
            if retryCount == numRetriesBeforeSuccess {
                self.mockSession.mockDataTaskError = nil
            }

            return .retryAfter(retryDelay)
        }

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [RetryPolicy.custom(mockRule)]
        )

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(response):
                XCTAssertEqual(response.value, mockData)
                XCTAssertEqual(response.response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }
    
    // MARK: with request interceptor
    
    func testFetch_WithRequestInterceptor_ShouldCallMakeRequestScheduleAndSuccessfulTaskMethods() {
        let makeRequestExpectation = self.expectation(description: "intercept make request 🤙")
        let scheduledTaskExpectation = self.expectation(description: "intercept scheduled task 🤙")
        let successfulTaskExpectation = self.expectation(description: "intercept successful task 🤙")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockResponse = successResponse
        let mockData = "🎉".data(using: .utf8)

        var mockDataTaskIdentifier: Int = -1

        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskInitInvokedClosure = { mockDataTaskIdentifier = $0.taskIdentifier }

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let mockInterceptor = MockURLSessionResourceInterceptor()

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [mockInterceptor]
        )

        mockInterceptor.didInvokeInterceptMakeRequestResult = { result, handler in
            defer { makeRequestExpectation.fulfill() }
            XCTAssertDumpsEqual(result, .success(mockRequest))
            return handler(result)
        }

        mockInterceptor.didInvokeInterceptScheduledTask = { identifier, request, retryState in
            defer { scheduledTaskExpectation.fulfill() }
            XCTAssertEqual(identifier, mockDataTaskIdentifier)
            XCTAssertEqual(request, mockRequest)
            XCTAssertDumpsEqual(retryState, .empty)
        }

        mockInterceptor.didInvokeInterceptSuccessfulTask = { identifier, request, data, response, retryState in
            defer { successfulTaskExpectation.fulfill() }

            XCTAssertEqual(identifier, mockDataTaskIdentifier)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(data, mockData)
            XCTAssertEqual(response, mockResponse)
            XCTAssertDumpsEqual(retryState, .empty)
        }

        mockInterceptor.didInvokeInterceptFailedTask = { _, _, _, _, _, _ in
            XCTFail("unexpected failed session task intercept!")
            return .none
        }
        
        networkStack.fetch(resource: resource) { _ in }
    }

    // MARK: - fetch (failure)

    func testFetch_WithNetworkFailureError_ShouldThrowAnURLError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockError = URLError(.notConnectedToInternet)

        mockSession.mockDataTaskError = mockError

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.url(mockError)):
                break
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithNonHTTPKindResponse_ShouldThrowABadResponseError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.badResponse):
                // 🤠 well done sir
                break
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithFailureStatusCodeResponseAndNilAPIError_ShouldThrowHTTPError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockResponse = failureResponse

        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskData = nil

        resource = .mock(errorDecoding: .init { _, _ in nil })

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.http(HTTP.StatusCode(mockResponse.statusCode), nil, mockResponse)):
                break
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithFailureStatusCodeResponseAndNonNilAPIError_ShouldThrowHTTPErrorWithAPIError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "💩".data(using: .utf8)!
        let mockResponse = failureResponse

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse

        resource = .mock(
            errorDecoding: .init {
                XCTAssertEqual($0, mockData)
                XCTAssertEqual($1, mockResponse)
                return MockError.🧨
            }
        )

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.http(receiveStatusCode, MockError.🧨?, receivedResponse)):
                XCTAssertEqual(receiveStatusCode.statusCode, mockResponse.statusCode)
                XCTAssertEqual(receivedResponse, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithEmptyResponseData_ShouldThrowANoDataError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockResponse = successResponse

        mockSession.mockDataTaskData = nil
        mockSession.mockURLResponse = mockResponse

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.noData(response)):
                XCTAssertEqual(response, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithNoValidationClosure_ShouldPerformDefaultHandling() {
        let expectation1 = self.expectation(description: "testAuthenticationCompletionHandler")
        let expectation2 = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        mockSession.mockAuthenticationCompletionHandler = { (authChallengeDisposition, credential) in
            XCTAssertEqual(authChallengeDisposition, .performDefaultHandling)

            expectation1.fulfill()
        }

        networkStack.fetch(resource: resource) { result in
            expectation2.fulfill()
        }
    }

    func testFetch_WithValidationClosure_ShouldInvokeValidationClosure() {
        let expectation1 = self.expectation(description: "testAuthenticationChallengeValidator")
        let expectation2 = self.expectation(description: "testAuthenticationCompletionHandler")
        let expectation3 = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let testAuthenticationChallenge = URLAuthenticationChallenge()
        let testAuthDisposition = URLSession.AuthChallengeDisposition.useCredential
        let testCredential = URLCredential()

        let testAuthenticationChallengeHandler = MockAuthenticationChallengeHandler()
        testAuthenticationChallengeHandler.mockHandleClosure = { challenge in
            defer { expectation1.fulfill() }
            XCTAssert(challenge === testAuthenticationChallenge)

            return (testAuthDisposition, testCredential)
        }

        networkStack = Network.URLSessionNetworkStack(authenticationChallengeHandler: testAuthenticationChallengeHandler,
                                                      retryQueue: retryQueue)
        mockSession = MockURLSession(delegate: networkStack)
        mockSession.mockAuthenticationChallenge = testAuthenticationChallenge
        mockSession.mockAuthenticationCompletionHandler = { (authChallengeDisposition, credential) in
            XCTAssertEqual(authChallengeDisposition, testAuthDisposition)
            XCTAssertEqual(credential, testCredential)
            expectation2.fulfill()
        }

        networkStack.session = mockSession

        networkStack.fetch(resource: resource) { result in
            expectation3.fulfill()
        }
    }

    func testFetch_WithThrowingMakeRequest_ShouldThrowTheNoRequestError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "makeRequest")
        defer { waitForExpectations(timeout: expectationTimeout) }

        resource = .mock(
            baseRequestMaking: .init { handler in
                expectation2.fulfill()
                return handler(.failure(MockError.🔥))
            },
            errorDecoding: .init { _, _ in nil }
        )

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.noRequest(MockError.🔥)):
                // 🤠 well done sir
                break
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    // MARK: with retry policy

    func testFetchWithRetryPolicy_WithNoRetryActionAfterFailure_ShouldFailWithRetryError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = URLError(.badURL)

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetries = 3
        var retryCount = 0
        let baseRetryDelay: Retry.Delay = 0.01

        let expectedError = Network.URLSessionError.url(mockError)

        expectation2.expectedFulfillmentCount = numRetries

        let mockRule: RetryPolicy.Rule = { error, state, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, expectedError)
            XCTAssertEqual(state.errors.count, retryCount)
            state.errors.forEach { XCTAssertDumpsEqual($0, expectedError) }
            XCTAssertEqual(state.totalDelay, baseRetryDelay * Double(retryCount))
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            return retryCount < numRetries
                ? .retryAfter(baseRetryDelay)
                : .noRetry(.custom(MockError.💣))
        }

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [RetryPolicy.custom(mockRule)]
        )

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.retry(.custom(MockError.💣), retryState)):
                XCTAssertDumpsEqual(
                    retryState,
                    .init(
                        errors: (0..<numRetries).map { _ in expectedError },
                        totalDelay: baseRetryDelay * Double(numRetries - 1)
                    )
                )
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchWithRetryPolicy_WithRetryActionAfterFailureAndCancelled_ShouldFailWithCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = URLError(.badURL)

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)

        let expectedError = Network.URLSessionError.url(mockError)

        let cancelable = CancelableBag()

        let mockRule: RetryPolicy.Rule = { error, state, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, expectedError)
            XCTAssertEqual(state.errors.count, 0)
            XCTAssertEqual(state.totalDelay, 0)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            cancelable.cancel()

            return .retry
        }

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [RetryPolicy.custom(mockRule)]
        )

        mockSession.delegateQueue.isSuspended = true

        cancelable += networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.cancelled):
                break
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        mockSession.delegateQueue.isSuspended = false
    }

    func testFetchWithRetryPolicy_WithRetryAfterActionAfterFailureAndCancelledBeforeScheduling_ShouldFailWithRetryCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = URLError(.badURL)

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let retryDelay: Retry.Delay = 0.01

        let expectedError = Network.URLSessionError.url(mockError)

        let cancelable = CancelableBag()

        let mockRule: RetryPolicy.Rule = { error, state, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, expectedError)
            XCTAssertEqual(state.errors.count, 0)
            XCTAssertEqual(state.totalDelay, 0)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            cancelable.cancel()

            return .retryAfter(retryDelay)
        }

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [RetryPolicy.custom(mockRule)]
        )

        mockSession.delegateQueue.isSuspended = true

        cancelable += networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.cancelled):
                break
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        mockSession.delegateQueue.isSuspended = false
    }

    // MARK: with request interceptor

    func testFetch_WithRequestInterceptor_ShouldCallMakeRequestScheduleAndFailedTaskMethods() {
        let makeRequestExpectation = self.expectation(description: "intercept make request 🤙")
        let scheduledTaskExpectation = self.expectation(description: "intercept scheduled task 🤙")
        let failedTaskExpectation = self.expectation(description: "intercept failed task 🤙")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = failureResponse
        let mockError = URLError(.badURL)

        var mockDataTaskIdentifier: Int = -1

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        mockSession.mockDataTaskInitInvokedClosure = { mockDataTaskIdentifier = $0.taskIdentifier }

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let mockInterceptor = MockURLSessionResourceInterceptor()

        resource = .mock(
            baseRequestMaking: .init { handler in handler(.success(mockRequest)) },
            interceptors: [mockInterceptor]
        )

        mockInterceptor.didInvokeInterceptMakeRequestResult = { result, handler in
            defer { makeRequestExpectation.fulfill() }
            XCTAssertDumpsEqual(result, .success(mockRequest))
            return handler(result)
        }

        mockInterceptor.didInvokeInterceptScheduledTask = { identifier, request, retryState in
            defer { scheduledTaskExpectation.fulfill() }
            XCTAssertEqual(identifier, mockDataTaskIdentifier)
            XCTAssertEqual(request, mockRequest)
            XCTAssertDumpsEqual(retryState, .empty)
        }

        mockInterceptor.didInvokeInterceptSuccessfulTask = { _, _, _, _, _ in
            XCTFail("unexpected failed session task intercept!")
        }

        mockInterceptor.didInvokeInterceptFailedTask = { identifier, request, data, response, error, retryState in
            defer { failedTaskExpectation.fulfill() }

            XCTAssertEqual(identifier, mockDataTaskIdentifier)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(data, mockData)
            XCTAssertEqual(response, mockResponse)
            XCTAssertDumpsEqual(error, Network.URLSessionError.url(mockError))
            XCTAssertDumpsEqual(retryState, .empty)

            return .none
        }

        networkStack.fetch(resource: resource) { _ in }
    }
}

extension Network.URLSessionResource {

    static func mock(
        baseRequestMaking: Network.BaseRequestMaking<URLRequest> =
            .init { handler in handler(.success(URLRequest(url: URL(string: "https://mindera.com")!))) },
        errorDecoding: Network.ErrorDecoding<Data, URLResponse> = .init { _, _ in MockError.💣 },
        interceptors: [URLSessionResourceInterceptor] = [],
        retryActionPriority: @escaping Retry.Action.CompareClosure = Retry.Action.mostPrioritary
    ) -> Self {

        .init(
            baseRequestMaking: baseRequestMaking,
            errorDecoding: errorDecoding,
            interceptors: interceptors,
            retryActionPriority: retryActionPriority
        )
    }
}

private enum MockError: Swift.Error { case 💣, 🧨, 🔥 }
