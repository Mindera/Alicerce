//
//  URLSessionNetworkStackTestCase.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class URLSessionNetworkStackTestCase: XCTestCase {

    private var networkStack: Network.URLSessionNetworkStack!
    private var mockSession: MockURLSession!

    private var authenticatorNetworkStack: Network.URLSessionNetworkStack!
    private var mockAuthenticator: MockNetworkAuthenticator!
    private var mockAuthenticatorSession: MockURLSession!
    
    private var mockRequestHandler: MockRequestInterceptor!
    private var requestHandlerNetworkStack: Network.URLSessionNetworkStack!
    private var mockRequestHandlerSession: MockURLSession!

    enum APIError: Error {
        case 💩
        case 💥
    }

    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func setUp() {
        super.setUp()

        let url = URL(string: "http://0.0.0.0")!
        networkStack = Network.URLSessionNetworkStack(baseURL: url)
        mockSession = MockURLSession(delegate: networkStack)

        networkStack.session = mockSession

        mockAuthenticator = MockNetworkAuthenticator()
        authenticatorNetworkStack = Network.URLSessionNetworkStack(baseURL: url, authenticator: mockAuthenticator)
        mockAuthenticatorSession = MockURLSession(delegate: authenticatorNetworkStack)

        authenticatorNetworkStack.session = mockAuthenticatorSession
     
        mockRequestHandler = MockRequestInterceptor()
        requestHandlerNetworkStack = Network.URLSessionNetworkStack(baseURL: url,
                                                                    requestInterceptors: [mockRequestHandler])
        mockRequestHandlerSession = MockURLSession(delegate: requestHandlerNetworkStack)
        
        requestHandlerNetworkStack.session = mockRequestHandlerSession
    }

    override func tearDown() {
        networkStack = nil
        mockSession = nil
        
        mockAuthenticatorSession = nil
        authenticatorNetworkStack = nil
        mockAuthenticator = nil
        
        mockRequestHandlerSession = nil
        requestHandlerNetworkStack = nil
        mockRequestHandler = nil

        super.tearDown()
    }

    private let resource = Resource<Void, APIError>(path: "",
                                                    method: .GET,
                                                    parser: { _ in () },
                                                    apiErrorParser: {_ in .💥 })

    // MARK: - Success tests

    // MARK: without authenticator

    func testConvenienceInit_WithValidProperties_ShouldPopulateAllProperties() {
        let expectation = self.expectation(description: "testConvenienceInit")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let url = URL(string: "http://0.0.0.0")!
        let networkConfiguration = Network.Configuration(baseURL: url)

        networkStack = Network.URLSessionNetworkStack(configuration: networkConfiguration)
        mockSession = MockURLSession(delegate: networkStack)

        mockSession.mockURLResponse = HTTPURLResponse(url: url,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockSession.mockDataTaskData = mockData

        networkStack.session = mockSession

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) in
            do {
                let _ = try inner()
            } catch {
                XCTFail("🔥: unexpected error \(error)")
            }
            expectation.fulfill()
        }
    }

    func testFetch_WhenResponseIsSuccessful_ShouldCallCompletionClosureWithData() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockSession.mockDataTaskData = mockData

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let data = try inner()

                XCTAssertEqual(data, mockData)
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchCancel_ShouldCancelTask() {
        let expectation = self.expectation(description: "testFetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        mockSession.mockDataTaskData = "🎉".data(using: .utf8)
        mockSession.mockDataTaskCancelInvokedClosure = {
            expectation.fulfill()
        }

        let cancelable = networkStack.fetch(resource: resource) { _ in }

        cancelable.cancel()
    }

    // MARK: with authenticator

    func testConvenienceInitWithAuthenticator_WithValidProperties_ShouldPopulateAllProperties() {
        let expectation = self.expectation(description: "testConvenienceInitWithAuthenticator")
        let expectation2 = self.expectation(description: "authenticate")
        let expectation3 = self.expectation(description: "shouldRetry")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let url = URL(string: "http://0.0.0.0")!
        mockAuthenticator = MockNetworkAuthenticator()
        let networkConfiguration = Network.Configuration(baseURL: url, authenticator: mockAuthenticator)

        authenticatorNetworkStack = Network.URLSessionNetworkStack(configuration: networkConfiguration)
        mockAuthenticatorSession = MockURLSession(delegate: authenticatorNetworkStack)

        mockAuthenticatorSession.mockURLResponse = HTTPURLResponse(url: url,
                                                                   statusCode: 200,
                                                                   httpVersion: nil,
                                                                   headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockAuthenticatorSession.mockDataTaskData = mockData

        authenticatorNetworkStack.session = mockAuthenticatorSession

        mockAuthenticator.authenticateClosure = {
            expectation2.fulfill()
            return $0
        }

        mockAuthenticator.shouldRetryClosure = { _, _, _, _ in
            expectation3.fulfill()
            return false
        }

        authenticatorNetworkStack.fetch(resource: resource) { (inner: () throws -> Data) in
            do {
                let _ = try inner()
            } catch {
                XCTFail("🔥: unexpected error \(error)")
            }
            expectation.fulfill()
        }
    }

    func testFetchWithAuthenticator_WhenResponseIsSuccessful_ShouldCallCompletionClosureWithData() {
        let expectation = self.expectation(description: "testFetchWithAuthenticator")
        let expectation2 = self.expectation(description: "authenticate")
        let expectation3 = self.expectation(description: "shouldRetry")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!

        mockAuthenticatorSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                                   statusCode: 200,
                                                                   httpVersion: nil,
                                                                   headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockAuthenticatorSession.mockDataTaskData = mockData

        mockAuthenticator.authenticateClosure = {
            expectation2.fulfill()
            return $0
        }

        mockAuthenticator.shouldRetryClosure = { _, _, _, _ in
            expectation3.fulfill()
            return false
        }

        authenticatorNetworkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let data = try inner()

                XCTAssertEqual(data, mockData)
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchWithAuthenticator_WhenShouldRetry_ShouldCallAuthenticateRequestAgain() {
        let expectation = self.expectation(description: "testFetchWithAuthenticator")
        let expectation2 = self.expectation(description: "authenticate")
        let expectation3 = self.expectation(description: "shouldRetry")

        expectation2.expectedFulfillmentCount = 2
        expectation3.expectedFulfillmentCount = 2

        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        defer {  }

        let baseURL = URL(string: "http://")!

        mockAuthenticatorSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                                   statusCode: 200,
                                                                   httpVersion: nil,
                                                                   headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockAuthenticatorSession.mockDataTaskData = mockData

        var retryCount = 2

        mockAuthenticator.authenticateClosure = {
            expectation2.fulfill()
            return $0
        }

        mockAuthenticator.shouldRetryClosure = { _, _, _, _ in
            retryCount -= 1

            expectation3.fulfill()
            return retryCount > 0
        }

        authenticatorNetworkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let data = try inner()

                XCTAssertEqual(data, mockData)
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetchCancelWithAuthenticator_ShouldCancelTask() {
        let expectation = self.expectation(description: "testFetchCancelWithAuthenticator")
        let expectation2 = self.expectation(description: "authenticate")
        let expectation3 = self.expectation(description: "shouldRetry")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!

        mockAuthenticatorSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                                   statusCode: 200,
                                                                   httpVersion: nil,
                                                                   headerFields: nil)!

        mockAuthenticatorSession.mockDataTaskData = "🎉".data(using: .utf8)
        mockAuthenticatorSession.mockDataTaskCancelInvokedClosure = {
            expectation.fulfill()
        }

        mockAuthenticator.authenticateClosure = {
            expectation2.fulfill()
            return $0
        }

        mockAuthenticator.shouldRetryClosure = { _, _, _, _ in
            expectation3.fulfill()
            return false
        }

        let cancelable = authenticatorNetworkStack.fetch(resource: resource) { _ in }

        cancelable.cancel()
    }
    
    // MARK: - RequestHandler tests
    
    func testFetch_WithRequestHandler_ShouldCallHandleAndRequest() {
        let expectationRequestHandlerHandle = self.expectation(description: "RequestHandler:handle 🤙")
        let expectationRequestHandlerRequest = self.expectation(description: "RequestHandler:request 🤙")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }
        
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
        
        let cancelable = requestHandlerNetworkStack.fetch(resource: resource) { _ in }
        
        cancelable.cancel()
    }

    // MARK: - Error tests

    func testFetch_WithNetworkFailureError_ShouldThrowAnURLError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!
        let statusCode = 500
        let mockError = NSError(domain: "☠️", code: statusCode, userInfo: nil)

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!
        mockSession.mockDataTaskError = mockError

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch let Network.Error.url(receivedError as NSError) {
                XCTAssertEqual(receivedError, mockError)
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithNonHTTPKindResponse_ShouldThrowABadResponseError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch Network.Error.badResponse {
                // 🤠 well done sir
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }
            expectation.fulfill()
        }
    }

    func testFetch_WithFailureStatusCodeResponseAndEmptyData_ShouldThrowStatusCodeErrorAndNoAPIError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!
        let statusCode = 500

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        mockSession.mockDataTaskData = nil

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch let Network.Error.http(code: receiveStatusCode, apiError: nil) {
                XCTAssertEqual(receiveStatusCode.rawValue, statusCode)
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithFailureStatusCodeResponseAndErrorData_ShouldThrowStatusCodeErrorAndAPIError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!
        let statusCode = 500

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        let mockData = "💩".data(using: .utf8)!
        mockSession.mockDataTaskData = mockData

        let resource = Resource<Void, APIError>(path: "",
                                                method: .GET,
                                                parser: { _ in () },
                                                apiErrorParser: {
                                                    XCTAssertEqual($0, mockData)
                                                    return .💩
                                                })

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch let Network.Error.http(code: receiveStatusCode, apiError: APIError.💩?) {
                XCTAssertEqual(receiveStatusCode.rawValue, statusCode)
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithEmptyResponseData_ShouldThrowANoDataError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!
        mockSession.mockDataTaskData = nil

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch Network.Error.noData {
                // 🤠 well done sir
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }

    func testFetch_WithNoValidationClosure_ShouldPerformDefaultHandling() {
        let expectation1 = self.expectation(description: "testAuthenticationCompletionHandler")
        let expectation2 = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        mockSession.mockAuthenticationCompletionHandler = { (authChallengeDisposition, credential) in
            XCTAssertEqual(authChallengeDisposition, .performDefaultHandling)

            expectation1.fulfill()
        }

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            expectation2.fulfill()
        }
    }

    func testFetch_WithValidationClosure_ShouldInvokeValidationClosure() {
        let expectation1 = self.expectation(description: "testAuthenticationChallengeValidator")
        let expectation2 = self.expectation(description: "testAuthenticationCompletionHandler")
        let expectation3 = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let testAuthenticationChallenge = URLAuthenticationChallenge()
        let testAuthDisposition = URLSession.AuthChallengeDisposition.useCredential
        let testCredential = URLCredential()

        let testAuthenticationChallengeValidator: Network.AuthenticationChallengeValidatorClosure = { (challenge, completionHandler) in
            XCTAssert(challenge === testAuthenticationChallenge)

            completionHandler(testAuthDisposition, testCredential)
            expectation1.fulfill()
        }

        let url = URL(string: "http://localhost")!

        networkStack = Network.URLSessionNetworkStack(baseURL: url,
                                                      authenticationChallengeValidator: testAuthenticationChallengeValidator)
        mockSession = MockURLSession(delegate: networkStack)
        mockSession.mockAuthenticationChallenge = testAuthenticationChallenge
        mockSession.mockAuthenticationCompletionHandler = { (authChallengeDisposition, credential) in
            XCTAssertEqual(authChallengeDisposition, testAuthDisposition)
            XCTAssertEqual(credential, testCredential)
            expectation2.fulfill()
        }

        networkStack.session = mockSession

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            expectation3.fulfill()
        }
    }

    func testFetchWithAuthenticator_WithThrowingAuthenticate_ShouldThrowTheAuthenticateError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        mockAuthenticator.authenticateClosure = { _ in throw APIError.💩 }

        authenticatorNetworkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch Network.Error.authenticator(APIError.💩) {
                // expected error
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }
    }
}


// MARK: - Network Mocks

final class MockURLSession: URLSession {

    var mockDataTaskData: Data? = Data()
    var mockDataTaskError: Error? = nil
    var mockURLResponse: URLResponse = URLResponse()

    var mockDataTaskResumeInvokedClosure: (() -> Void)?
    var mockDataTaskCancelInvokedClosure: (() -> Void)?

    var mockAuthenticationChallenge: URLAuthenticationChallenge = URLAuthenticationChallenge()
    var mockAuthenticationCompletionHandler: Network.AuthenticationCompletionClosure = { _, _  in }

    private let _configuration: URLSessionConfiguration
    private let _delegate: URLSessionDelegate?
    private let _delegateQueue: OperationQueue

    private var mockDataTask: MockURLSessionDataTask?

    @objc
    override var configuration: URLSessionConfiguration { return _configuration }

    @objc
    override var delegate: URLSessionDelegate? { return _delegate }

    @objc
    override var delegateQueue: OperationQueue { return _delegateQueue }

    init(configuration: URLSessionConfiguration = .default,
         delegate: URLSessionDelegate?,
         delegateQueue queue: OperationQueue = OperationQueue()) {

        _configuration = configuration
        _delegate = delegate
        _delegateQueue = queue

        super.init()
    }

    override func dataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {

        let dataTask = MockURLSessionDataTask()

        dataTask.resumeInvokedClosure = { [weak self] in
            guard let strongSelf = self else { fatalError("🔥: `self` must be defined!") }

            strongSelf.mockDataTaskResumeInvokedClosure?()

            strongSelf.delegate?.urlSession?(strongSelf,
                                             didReceive: strongSelf.mockAuthenticationChallenge,
                                             completionHandler: strongSelf.mockAuthenticationCompletionHandler)

            completionHandler(strongSelf.mockDataTaskData, strongSelf.mockURLResponse, strongSelf.mockDataTaskError)
        }

        dataTask.cancelInvokedClosure = { [weak self] in
            self?.mockDataTaskCancelInvokedClosure?()
        }

        // keep a strong reference to the task, otherwise it gets deallocated
        self.mockDataTask = dataTask

        return dataTask
    }
}

final class MockURLSessionDataTask: URLSessionDataTask {

    var resumeInvokedClosure: (() -> Void)?
    var cancelInvokedClosure: (() -> Void)?

    override func resume() {
        resumeInvokedClosure?()
    }

    override func cancel() {
        cancelInvokedClosure?()
    }
}

final class MockNetworkAuthenticator: NetworkAuthenticator {

    var authenticateClosure: ((URLRequest) throws -> URLRequest)?
    var shouldRetryClosure: ((URLRequest, Data?, HTTPURLResponse?, Error?) -> Bool)?

    func authenticate(request: URLRequest,
                      performRequest: @escaping NetworkAuthenticator.PerformRequestClosure) -> Cancelable {
        return performRequest { try authenticateClosure?(request) ?? request }
    }

    func shouldRetry(request: URLRequest, data: Data?, response: HTTPURLResponse?, error: Error?) -> Bool {
        return shouldRetryClosure?(request, data, response, error) ?? false
    }
}

private final class MockRequestInterceptor: RequestInterceptor {
    var interceptRequestClosure: ((URLRequest) -> Void)?
    var interceptResponseClosure: ((URLResponse?, Data?, Error?, URLRequest?) -> Void)?
    
    func intercept(request: URLRequest) {
        interceptRequestClosure?(request)
    }
    func intercept(response: URLResponse?, data: Data?, error: Error?, for request: URLRequest) {
        interceptResponseClosure?(response, data, error, request)
    }
}
