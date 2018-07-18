import XCTest
import Result
@testable import Alicerce

private struct URLSessionMockResource<T, Error: Swift.Error>: StaticNetworkResource & RetryableResource {

    static var empty: Data { return Data() }

    var url: URL
    var path: String
    var method: HTTP.Method
    var headers: HTTP.Headers?
    var query: HTTP.Query?
    var body: Data?

    var retriedAfterErrors: [Swift.Error]
    var totalRetriedDelay: ResourceRetry.Delay
    var retryPolicies: [ResourceRetry.Policy<Data, URLRequest, URLResponse>]

    let parse: ResourceMapClosure<Data, T>
    let serialize: ResourceMapClosure<T, Data>
    let errorParser: ResourceErrorParseClosure<Data, Error>
}

final class URLSessionNetworkStackTestCase: XCTestCase {

    private var networkStackRetryQueue: DispatchQueue!
    private var networkStack: Network.URLSessionNetworkStack!
    private var mockSession: MockURLSession!

    private var authenticatorNetworkStackRetryQueue: DispatchQueue!
    private var authenticatorNetworkStack: Network.URLSessionNetworkStack!
    private var mockAuthenticator: MockNetworkAuthenticator!
    private var mockAuthenticatorSession: MockURLSession!
    
    private var mockRequestHandler: MockRequestInterceptor!
    private var requestHandlerNetworkStackRetryQueue: DispatchQueue!
    private var requestHandlerNetworkStack: Network.URLSessionNetworkStack!
    private var mockRequestHandlerSession: MockURLSession!

    private enum MockError: Error {
        case 🔥
    }

    private enum APIError: Error {
        case 💩
        case 💥
    }

    private typealias Resource = URLSessionMockResource<Void, APIError>
    private typealias RetryPolicy = Resource.RetryPolicy

    fileprivate let expectationTimeout: TimeInterval = 5

    override func setUp() {
        super.setUp()

        networkStackRetryQueue = DispatchQueue(label: "network-stack.retry-queue")
        networkStack = Network.URLSessionNetworkStack(retryQueue: networkStackRetryQueue)
        mockSession = MockURLSession(delegate: networkStack)

        networkStack.session = mockSession

        mockAuthenticator = MockNetworkAuthenticator()
        authenticatorNetworkStackRetryQueue = DispatchQueue(label: "authenticator-network-stack.retry-queue")
        authenticatorNetworkStack = Network.URLSessionNetworkStack(authenticator: mockAuthenticator,
                                                                   retryQueue: authenticatorNetworkStackRetryQueue)
        mockAuthenticatorSession = MockURLSession(delegate: authenticatorNetworkStack)

        authenticatorNetworkStack.session = mockAuthenticatorSession
     
        mockRequestHandler = MockRequestInterceptor()
        requestHandlerNetworkStackRetryQueue = DispatchQueue(label: "request-handler-network-stack.retry-queue")
        requestHandlerNetworkStack = Network.URLSessionNetworkStack(requestInterceptors: [mockRequestHandler],
                                                                    retryQueue: requestHandlerNetworkStackRetryQueue)
        mockRequestHandlerSession = MockURLSession(delegate: requestHandlerNetworkStack)
        
        requestHandlerNetworkStack.session = mockRequestHandlerSession
    }

    override func tearDown() {
        networkStackRetryQueue = nil
        networkStack = nil
        mockSession = nil

        mockAuthenticatorSession = nil
        authenticatorNetworkStackRetryQueue = nil
        authenticatorNetworkStack = nil
        mockAuthenticator = nil
        
        mockRequestHandlerSession = nil
        requestHandlerNetworkStackRetryQueue = nil
        requestHandlerNetworkStack = nil
        mockRequestHandler = nil

        super.tearDown()
    }

    private func buildResource(url: URL = URL(string: "http://0.0.0.0")!,
                               parse: @escaping ResourceMapClosure<Data, Void> = { _ in () },
                               serialize: @escaping ResourceMapClosure<Void, Data> = { _ in Data() },
                               errorParser: @escaping ResourceErrorParseClosure<Data, APIError> = { _ in APIError.💥 })
    -> Resource  {
        return URLSessionMockResource(url: url,
                                      path: "",
                                      method: .GET,
                                      headers: nil,
                                      query: nil,
                                      body: nil,
                                      retriedAfterErrors: [],
                                      totalRetriedDelay: 0,
                                      retryPolicies: [],
                                      parse: parse,
                                      serialize: serialize,
                                      errorParser: errorParser)
    }

    // MARK: - Success tests

    // MARK: without authenticator

    func testConvenienceInit_WithValidProperties_ShouldPopulateAllProperties() {
        let expectation = self.expectation(description: "testConvenienceInit")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let url = URL(string: "http://0.0.0.0")!
        let networkConfiguration = Network.Configuration(retryQueue: networkStackRetryQueue)

        networkStack = Network.URLSessionNetworkStack(configuration: networkConfiguration)
        mockSession = MockURLSession(delegate: networkStack)

        mockSession.mockURLResponse = HTTPURLResponse(url: url,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockSession.mockDataTaskData = mockData

        networkStack.session = mockSession

        let resource = buildResource(url: url)

        networkStack.fetch(resource: resource) { result in

            if let error = result.error {
                XCTFail("🔥: unexpected error \(error)")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WhenResponseIsSuccessful_ShouldCallCompletionClosureWithData() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockSession.mockDataTaskData = mockData

        let resource = buildResource(url: baseURL)

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(data):
                XCTAssertEqual(data, mockData)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchCancel_ShouldCancelTask() {
        let expectation = self.expectation(description: "testFetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        mockSession.mockDataTaskData = "🎉".data(using: .utf8)
        mockSession.mockDataTaskCancelInvokedClosure = {
            expectation.fulfill()
        }

        let resource = buildResource(url: baseURL)

        let cancelable = networkStack.fetch(resource: resource) { _ in }

        cancelable.cancel()
    }

    // MARK: with authenticator

    func testConvenienceInitWithAuthenticator_WithValidProperties_ShouldPopulateAllProperties() {
        let expectation = self.expectation(description: "testConvenienceInitWithAuthenticator")
        let expectation2 = self.expectation(description: "authenticate")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let url = URL(string: "http://0.0.0.0")!
        mockAuthenticator = MockNetworkAuthenticator()
        let networkConfiguration = Network.Configuration(authenticator: mockAuthenticator,
                                                         retryQueue: authenticatorNetworkStackRetryQueue)

        authenticatorNetworkStack = Network.URLSessionNetworkStack(configuration: networkConfiguration)
        mockAuthenticatorSession = MockURLSession(delegate: authenticatorNetworkStack)

        mockAuthenticatorSession.mockURLResponse = HTTPURLResponse(url: url,
                                                                   statusCode: 200,
                                                                   httpVersion: nil,
                                                                   headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockAuthenticatorSession.mockDataTaskData = mockData

        authenticatorNetworkStack.session = mockAuthenticatorSession

        mockAuthenticator.mockAuthenticateClosure = {
            expectation2.fulfill()
            return .success($0)
        }

        let resource = buildResource(url: url)

        authenticatorNetworkStack.fetch(resource: resource) { result in

            if let error = result.error {
                XCTFail("🔥: unexpected error \(error)")
            }
            expectation.fulfill()
        }
    }

    func testFetchWithAuthenticator_WhenResponseIsSuccessful_ShouldCallCompletionClosureWithData() {
        let expectation = self.expectation(description: "testFetchWithAuthenticator")
        let expectation2 = self.expectation(description: "authenticate")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!

        mockAuthenticatorSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                                   statusCode: 200,
                                                                   httpVersion: nil,
                                                                   headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockAuthenticatorSession.mockDataTaskData = mockData

        mockAuthenticator.mockAuthenticateClosure = {
            expectation2.fulfill()
            return .success($0)
        }

        let resource = buildResource(url: baseURL)

        authenticatorNetworkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(data):
                XCTAssertEqual(data, mockData)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchWithAuthenticator_WhenRequestFailsAndAuthenticatorAllowsRetry_ShouldCallAuthenticateRequestAgain() {
        let expectation = self.expectation(description: "testFetchWithAuthenticator")
        let expectation2 = self.expectation(description: "authenticate")
        let expectation3 = self.expectation(description: "authenticatorRetry")

        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!
        let mockData = "🎉".data(using: .utf8)
        let mockError = MockError.🔥
        let mockResponse = HTTPURLResponse(url: baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockAuthenticatorSession.mockDataTaskData = mockData
        mockAuthenticatorSession.mockDataTaskError = mockError
        mockAuthenticatorSession.mockURLResponse = mockResponse

        let numRetriesBeforeSuccess = 2
        var retryCount = 0

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess + 1
        expectation3.expectedFulfillmentCount = numRetriesBeforeSuccess

        mockAuthenticator.mockAuthenticateClosure = {
            expectation2.fulfill()
            return .success($0)
        }

        var resource = buildResource(url: baseURL)

        mockAuthenticator.mockRetryPolicyRule = { previousErrors, totalDelay, request, error, payload, response in
            defer { expectation3.fulfill() }

            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, MockError.🔥) }
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(request, resource.request)
            XCTAssertDumpsEqual(error, MockError.🔥)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            // return success after N retries
            if retryCount == numRetriesBeforeSuccess {
                self.mockAuthenticatorSession.mockDataTaskError = nil
            }

            return .retry
        }

        resource.retryPolicies = [.custom(mockAuthenticator.retryPolicyRule())]

        authenticatorNetworkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(data):
                XCTAssertEqual(data, mockData)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchCancelWithAuthenticator_ShouldCancelTask() {
        let expectation = self.expectation(description: "testFetchCancelWithAuthenticator")
        let expectation2 = self.expectation(description: "authenticate")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!

        mockAuthenticatorSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                                   statusCode: 200,
                                                                   httpVersion: nil,
                                                                   headerFields: nil)!

        mockAuthenticatorSession.mockDataTaskData = "🎉".data(using: .utf8)
        mockAuthenticatorSession.mockDataTaskCancelInvokedClosure = {
            expectation.fulfill()
        }

        mockAuthenticator.mockAuthenticateClosure = {
            expectation2.fulfill()
            return .success($0)
        }

        var resource = buildResource(url: baseURL)
        resource.retryPolicies = [.custom(mockAuthenticator.retryPolicyRule())]

        let cancelable = authenticatorNetworkStack.fetch(resource: resource) { _ in }

        cancelable.cancel()
    }

    // MARK: with retry policy

    func testFetchWithRetryPolicy_WhenPolicyReturnsRetry_ShouldFetchAgain() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "mockRule")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!
        let mockData = "🎉".data(using: .utf8)
        let mockError = MockError.🔥
        let mockResponse = HTTPURLResponse(url: baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let numRetriesBeforeSuccess = 2
        var retryCount = 0

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        var resource = buildResource(url: baseURL)

        let mockRule: RetryPolicy.Rule = { previousErrors, totalDelay, request, error, payload, response in
            defer { expectation2.fulfill() }

            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, MockError.🔥) }
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(request, resource.request)
            XCTAssertDumpsEqual(error, MockError.🔥)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            // return success after 2nd retry
            if retryCount == numRetriesBeforeSuccess {
                self.mockSession.mockDataTaskError = nil
            }

            return .retry
        }

        resource.retryPolicies = [.custom(mockRule)]

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(data):
                XCTAssertEqual(data, mockData)
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

        let baseURL = URL(string: "http://")!
        let mockData = "🎉".data(using: .utf8)
        let mockError = MockError.🔥
        let mockResponse = HTTPURLResponse(url: baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let numRetriesBeforeSuccess = 3
        var retryCount = 0
        let baseRetryDelay: ResourceRetry.Delay = 0.01

        expectation2.expectedFulfillmentCount = numRetriesBeforeSuccess

        var resource = buildResource(url: baseURL)

        let mockRule: RetryPolicy.Rule = { previousErrors, totalDelay, request, error, payload, response in
            defer { expectation2.fulfill() }

            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, MockError.🔥) }
            XCTAssertEqual(totalDelay, baseRetryDelay * Double(retryCount))
            XCTAssertEqual(request, resource.request)
            XCTAssertDumpsEqual(error, MockError.🔥)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            // return success after 2nd retry
            if retryCount == numRetriesBeforeSuccess {
                self.mockSession.mockDataTaskError = nil
            }

            return .retryAfter(baseRetryDelay)
        }

        resource.retryPolicies = [.custom(mockRule)]

        networkStack.fetch(resource: resource) { result in

            switch result {
            case let .success(data):
                XCTAssertEqual(data, mockData)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }
    
    // MARK: - RequestHandler tests
    
    func testFetch_WithRequestHandler_ShouldCallHandleAndRequest() {
        let expectationRequestHandlerHandle = self.expectation(description: "RequestHandler:handle 🤙")
        let expectationRequestHandlerRequest = self.expectation(description: "RequestHandler:request 🤙")
        defer { waitForExpectations(timeout: expectationTimeout) }
        
        let baseURL = URL(string: "http://")!
        
        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!
        
        let mockData = "🎉".data(using: .utf8)
        mockSession.mockDataTaskData = mockData
        
        mockRequestHandler.interceptRequestClosure = { _ in
            expectationRequestHandlerHandle.fulfill()
        }
        
        mockRequestHandler.interceptResponseClosure = { _, _, _, _ in
            expectationRequestHandlerRequest.fulfill()
        }

        let resource = buildResource(url: baseURL)
        
        let cancelable = requestHandlerNetworkStack.fetch(resource: resource) { _ in }
        
        cancelable.cancel()
    }

    // MARK: - Error tests

    func testFetch_WithNetworkFailureError_ShouldThrowAnURLError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!
        let statusCode = 500
        let mockError = NSError(domain: "☠️", code: statusCode, userInfo: nil)

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!
        mockSession.mockDataTaskError = mockError

        let resource = buildResource(url: baseURL)

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.url(receivedError as NSError)):
                XCTAssertEqual(receivedError, mockError)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithNonHTTPKindResponse_ShouldThrowABadResponseError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let resource = buildResource()

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

    func testFetch_WithFailureStatusCodeResponseAndEmptyData_ShouldThrowStatusCodeErrorAndNoAPIError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!
        let statusCode = 500



        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        mockSession.mockDataTaskData = nil

        let resource = buildResource(url: baseURL)

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.http(code: receiveStatusCode, apiError: nil)):
                XCTAssertEqual(receiveStatusCode.statusCode, statusCode)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithFailureStatusCodeResponseAndErrorData_ShouldThrowStatusCodeErrorAndAPIError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!
        let statusCode = 500

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        let mockData = "💩".data(using: .utf8)!
        mockSession.mockDataTaskData = mockData

        let resource = buildResource(url: baseURL, errorParser: {
            XCTAssertEqual($0, mockData)
            return APIError.💩
        })

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.http(code: receiveStatusCode, apiError: APIError.💩?)):
                XCTAssertEqual(receiveStatusCode.statusCode, statusCode)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithEmptyResponseData_ShouldThrowANoDataError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        let baseURL = URL(string: "http://")!

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!
        mockSession.mockDataTaskData = nil

        let resource = buildResource(url: baseURL)

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.noData):
                // 🤠 well done sir
                break
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

        let resource = buildResource()

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

        let resource = buildResource()

        networkStack.fetch(resource: resource) { result in
            expectation3.fulfill()
        }
    }

    func testFetchWithAuthenticator_WithThrowingAuthenticate_ShouldThrowTheAuthenticateError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout) }

        mockAuthenticator.mockAuthenticateClosure = { _ in .failure(AnyError(MockError.🔥)) }

        let resource = buildResource()

        authenticatorNetworkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.authenticator(MockError.🔥)):
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

        let baseURL = URL(string: "http://")!
        let mockData = "🎉".data(using: .utf8)
        let mockError = MockError.🔥
        let mockResponse = HTTPURLResponse(url: baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockSession.mockDataTaskData = mockData
        mockSession.mockDataTaskError = mockError
        mockSession.mockURLResponse = mockResponse

        let numRetries = 3
        var retryCount = 0
        let baseRetryDelay: ResourceRetry.Delay = 0.01

        expectation2.expectedFulfillmentCount = numRetries

        var resource = buildResource(url: baseURL)

        let mockRule: RetryPolicy.Rule = { previousErrors, totalDelay, request, error, payload, response in
            defer { expectation2.fulfill() }

            XCTAssertEqual(previousErrors.count, retryCount)
            previousErrors.forEach { XCTAssertDumpsEqual($0, MockError.🔥) }
            XCTAssertEqual(totalDelay, baseRetryDelay * Double(retryCount))
            XCTAssertEqual(request, resource.request)
            XCTAssertDumpsEqual(error, MockError.🔥)
            XCTAssertEqual(payload, mockData)
            XCTAssertEqual(response, mockResponse)

            retryCount += 1

            return retryCount < numRetries
                ? .retryAfter(baseRetryDelay)
                : .noRetry(.custom(MockNetworkAuthenticator.Error.🚫))
        }

        resource.retryPolicies = [.custom(mockRule)]

        networkStack.fetch(resource: resource) { result in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.retry(errors, delay, ResourceRetry.Error.custom(MockNetworkAuthenticator.Error.🚫))):
                XCTAssertDumpsEqual(errors, (0..<numRetries).map { _ in MockError.🔥 })
                XCTAssertEqual(delay, baseRetryDelay * Double(numRetries-1))
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }
}
