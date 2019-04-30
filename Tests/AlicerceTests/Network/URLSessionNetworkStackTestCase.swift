import XCTest
@testable import Alicerce

final class URLSessionNetworkStackTestCase: XCTestCase {

    private typealias Resource = MockResource<Void>
    private typealias RetryPolicy = Resource.RetryPolicy

    private enum MockError: Error {
        case 🔥
    }

    private var networkStackRetryQueue: DispatchQueue!
    private var networkStack: Network.URLSessionNetworkStack!
    private var mockSession: MockURLSession!
    private var requestInterceptor: MockRequestInterceptor!

    private var resource: Resource!

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

        requestInterceptor = MockRequestInterceptor()

        networkStackRetryQueue = DispatchQueue(label: "network-stack.retry-queue")
        networkStack = Network.URLSessionNetworkStack(requestInterceptors: [requestInterceptor],
                                                      retryQueue: networkStackRetryQueue)
        mockSession = MockURLSession(delegate: networkStack)

        networkStack.session = mockSession

        resource = Resource()
    }

    override func tearDown() {
        networkStackRetryQueue = nil
        networkStack = nil
        mockSession = nil
        requestInterceptor = nil

        resource = nil

        super.tearDown()
    }

    // MARK: - init

    func testConvenienceInit_WithValidProperties_ShouldPopulateAllProperties() {
        let expectation = self.expectation(description: "testConvenienceInit")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let networkConfiguration = Network.Configuration(retryQueue: networkStackRetryQueue)

        networkStack = Network.URLSessionNetworkStack(configuration: networkConfiguration)
        mockSession = MockURLSession(delegate: networkStack)

        networkStack.session = mockSession

        mockSession.mockDataTaskData = "🎉".data(using: .utf8)
        mockSession.mockURLResponse = successResponse

        resource.mockDecode = { _ in () }

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            expectation.fulfill()
        }
    }

    // MARK: - finishFetchesAndInvalidateSession

    func testFetchesTasksAndInvalidateSession_WithSetSession_ShouldCallFinishTasksAndInvalidateOnTheSession() {
        let expectation = self.expectation(description: "testFinishTasksAndInvalidateSession")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let networkConfiguration = Network.Configuration(retryQueue: networkStackRetryQueue)

        networkStack = Network.URLSessionNetworkStack(configuration: networkConfiguration)
        mockSession = MockURLSession(delegate: networkStack)

        networkStack.session = mockSession

        mockSession.didInvokeFinishTasksAndInvalidate = { expectation.fulfill() }

        networkStack.finishFetchesAndInvalidateSession()
    }

    // MARK: - fetch (success)

    func testFetch_WhenResponseIsSuccessful_ShouldCallCompletionClosureWithData() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse

        resource.mockDecode = { _ in () }

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

    func testFetch_WhenResponseIsSuccessfulWith204StatusCode_ShouldCallCompletionClosureWithEmptyData() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                           statusCode: 204,
                                           httpVersion: nil,
                                           headerFields: nil)!

        mockSession.mockDataTaskData = nil
        mockSession.mockURLResponse = mockResponse

        resource.mockDecode = { _ in () }

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

    func testFetch_WhenResponseIsSuccessfulWith205StatusCode_ShouldCallCompletionClosureWithEmptyData() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                           statusCode: 205,
                                           httpVersion: nil,
                                           headerFields: nil)!

        mockSession.mockDataTaskData = nil
        mockSession.mockURLResponse = mockResponse

        resource.mockDecode = { _ in () }

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
        let expectation3 = self.expectation(description: "performRequest")
        let expectation4 = self.expectation(description: "session dataTask")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        resource.mockMakeRequest = .success(mockRequest)

        resource.didInvokeMakeRequest = {
            expectation2.fulfill()
        }

        resource.didInvokeMakeRequestHandler = { _ in
            expectation3.fulfill()
        }

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

    func testFetchCancel_ShouldCancelTask() {
        let expectation = self.expectation(description: "testFetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout) }

        mockSession.mockDataTaskData = "🎉".data(using: .utf8)
        mockSession.mockURLResponse = successResponse
        mockSession.mockDataTaskCancelInvokedClosure = {
            expectation.fulfill()
        }

        resource.mockDecode = { _ in () }

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
        let mockError = MockError.🔥

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetriesBeforeSuccess = 2
        var retryCount = 0

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        let mockRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, mockError)
            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, mockError) }
            XCTAssertEqual(totalDelay, 0)
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

        resource.mockMakeRequest = .success(mockRequest)
        resource.mockRetryPolicies = [.custom(mockRule)]

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
        let mockError = MockError.🔥

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetriesBeforeSuccess = 3
        var retryCount = 0
        let baseRetryDelay: Retry.Delay = 0.01

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        let mockRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, mockError)
            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, mockError) }
            XCTAssertEqual(totalDelay, baseRetryDelay * Double(retryCount))
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

        resource.mockMakeRequest = .success(mockRequest)
        resource.mockRetryPolicies = [.custom(mockRule)]

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
        let mockError = MockError.🔥

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetriesBeforeSuccess = 3
        var retryCount = 0
        let retryDelay: Retry.Delay = 0

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        let mockRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, mockError)
            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, mockError) }
            XCTAssertEqual(totalDelay, 0)
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

        resource.mockMakeRequest = .success(mockRequest)
        resource.mockRetryPolicies = [.custom(mockRule)]

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
        let mockError = MockError.🔥

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetriesBeforeSuccess = 3
        var retryCount = 0
        let retryDelay: Retry.Delay = -1.337

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        let mockRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, mockError)
            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, mockError) }
            XCTAssertEqual(totalDelay, 0)
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

        resource.mockMakeRequest = .success(mockRequest)
        resource.mockRetryPolicies = [.custom(mockRule)]

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
    
    func testFetch_WithRequestInterceptor_ShouldCallHandleAndRequest() {
        let expectationRequestInterceptorHandleRequest = self.expectation(description: "intercept request 🤙")
        let expectationRequestInterceptorHandleResponse = self.expectation(description: "intercept response 🤙")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)

        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskData = mockData

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        resource.mockMakeRequest = .success(mockRequest)
        
        requestInterceptor.interceptRequestClosure = {

            XCTAssertEqual($0, mockRequest)

            expectationRequestInterceptorHandleRequest.fulfill()
        }
        
        requestInterceptor.interceptResponseClosure = { response, data, error, request in

            XCTAssertEqual(response, mockResponse)
            XCTAssertEqual(data, mockData)
            XCTAssertNil(error)
            XCTAssertEqual(request, mockRequest)

            expectationRequestInterceptorHandleResponse.fulfill()
        }
        
        networkStack.fetch(resource: resource) { _ in }
    }

    // MARK: - fetch (failure)

    func testFetch_WithNetworkFailureError_ShouldThrowAnURLError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockError = NSError(domain: "☠️", code: failureResponse.statusCode, userInfo: nil)
        let mockResponse = failureResponse

        mockSession.mockURLResponse = mockResponse
        mockSession.mockDataTaskError = mockError

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.url(receivedError as NSError, receivedResponse)):
                XCTAssertEqual(receivedError, mockError)
                XCTAssertEqual(receivedResponse, mockResponse)
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

        resource.mockDecodeError = { _, _ in return nil }

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.http(receiveStatusCode, receivedResponse)):
                XCTAssertEqual(receiveStatusCode.statusCode, mockResponse.statusCode)
                XCTAssertEqual(receivedResponse, mockResponse)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithFailureStatusCodeResponseAndNonNilAPIError_ShouldThrowAPIError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "💩".data(using: .utf8)!
        let mockResponse = failureResponse

        mockSession.mockDataTaskData = mockData
        mockSession.mockURLResponse = mockResponse

        resource.mockDecodeError = {
            XCTAssertEqual($0, mockData)
            XCTAssertEqual($1, mockResponse)
            return Resource.MockAPIError.💩
        }

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.api(Resource.MockAPIError.💩, receiveStatusCode, receivedResponse)):
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
                                                      retryQueue: networkStackRetryQueue)
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
        let expectation3 = self.expectation(description: "performRequest")
        defer { waitForExpectations(timeout: expectationTimeout) }

        resource.mockMakeRequest = .failure(MockError.🔥)

        resource.didInvokeMakeRequest = {
            expectation2.fulfill()
        }

        resource.didInvokeMakeRequestHandler = { _ in
            expectation3.fulfill()
        }

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

    func testFetchWithRetryPolicy_WhenPolicyReturnsNoRetry_ShouldFailWithRetryError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = MockError.🔥

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let numRetries = 3
        var retryCount = 0
        let baseRetryDelay: Retry.Delay = 0.01

        expectation2.expectedFulfillmentCount = numRetries

        let mockRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, mockError)
            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, mockError) }
            XCTAssertEqual(totalDelay, baseRetryDelay * Double(retryCount))
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            return retryCount < numRetries
                ? .retryAfter(baseRetryDelay)
                : .noRetry(.custom(MockRequestAuthenticator.Error.🚫))
        }

        resource.mockMakeRequest = .success(mockRequest)
        resource.mockRetryPolicies = [.custom(mockRule)]

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
             case let .failure(.retry(.custom(MockRequestAuthenticator.Error.🚫), errors, delay, response)):
                XCTAssertEqual(response, mockResponse)
                XCTAssertDumpsEqual(errors, (0..<numRetries).map { _ in mockError })
                XCTAssertEqual(delay, baseRetryDelay * Double(numRetries-1))
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchWithRetryPolicy_WhenPolicyReturnsRetryButCancelableIsCancelled_ShouldFailWithRetryCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = MockError.🔥

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)

        let cancelable = CancelableBag()

        let mockRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, mockError)
            XCTAssertEqual(previousErrors.count, 0)
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            cancelable.cancel()

            return .retry
        }

        resource.mockMakeRequest = .success(mockRequest)
        resource.mockRetryPolicies = [.custom(mockRule)]

        mockSession.delegateQueue.isSuspended = true

        cancelable += networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.retry(.cancelled, errors, delay, response)):
                XCTAssertEqual(response, mockResponse)
                XCTAssertDumpsEqual(errors, [mockError])
                XCTAssertEqual(delay, 0)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        mockSession.delegateQueue.isSuspended = false
    }

    func testFetchWithRetryPolicy_WhenPolicyReturnsRetryAfterButCancelableIsCancelledBeforeScheduling_ShouldFailWithRetryCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = MockError.🔥

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let retryDelay: Retry.Delay = 0.01

        let cancelable = CancelableBag()

        let mockRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, mockError)
            XCTAssertEqual(previousErrors.count, 0)
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            cancelable.cancel()

            return .retryAfter(retryDelay)
        }

        resource.mockMakeRequest = .success(mockRequest)
        resource.mockRetryPolicies = [.custom(mockRule)]

        mockSession.delegateQueue.isSuspended = true

        cancelable += networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.retry(.cancelled, errors, delay, response)):
                XCTAssertEqual(response, mockResponse)
                XCTAssertDumpsEqual(errors, [mockError])
                XCTAssertEqual(delay, 0)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        mockSession.delegateQueue.isSuspended = false
    }

    func testFetchWithRetryPolicy_WhenPolicyReturnsRetryAfterButCancelableIsCancelledAfterScheduling_ShouldFailWithRetryCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        // create the retryQueue as inactive, so we can cancel the resource after it is scheduled by activating it
        networkStackRetryQueue = DispatchQueue(label: "network-stack.retry-queue", attributes: [.initiallyInactive])
        networkStack = Network.URLSessionNetworkStack(requestInterceptors: [requestInterceptor],
                                                      retryQueue: networkStackRetryQueue)
        mockSession = MockURLSession(delegate: networkStack)
        networkStack.session = mockSession

        let mockData = "🎉".data(using: .utf8)
        let mockResponse = successResponse
        let mockError = MockError.🔥

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let mockRequest = URLRequest(url: URL(string: "https://mindera.com")!)
        let retryDelay: Retry.Delay = 0.01

        let cancelable = CancelableBag()

        let mockRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in
            defer { expectation2.fulfill() }

            let (request, payload, response) = metadata

            XCTAssertDumpsEqual(error, mockError)
            XCTAssertEqual(previousErrors.count, 0)
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(request, mockRequest)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            return .retryAfter(retryDelay)
        }

        resource.mockMakeRequest = .success(mockRequest)
        resource.mockRetryPolicies = [.custom(mockRule)]

        mockSession.delegateQueue.isSuspended = true

        cancelable += networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.retry(.cancelled, errors, delay, response)):
                XCTAssertEqual(response, mockResponse)
                XCTAssertDumpsEqual(errors, [mockError])
                XCTAssertEqual(delay, retryDelay)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        // schedule cancel before scheduling the fetch retry workItem
        networkStackRetryQueue.async {
            cancelable.cancel()
        }

        mockSession.delegateQueue.isSuspended = false

        wait(for: [expectation2], timeout: expectationTimeout)

        // wait for the retryAfter to be returned before activating the retryQueue, so that `isCancelled` is detected
        // inside the workItem
        networkStackRetryQueue.activate()
    }
}
