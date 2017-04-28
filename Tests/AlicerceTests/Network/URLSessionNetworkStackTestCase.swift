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
    }

    override func tearDown() {
        networkStack = nil
        mockSession = nil

        super.tearDown()
    }

    private let resource = Resource<Void>(path: "", method: .GET, parser: { _ in () })

    // MARK: - Success tests

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

    func testFetch_WithFailureStatusCodeResponse_ShouldThrowStatusCodeError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let baseURL = URL(string: "http://")!
        let statusCode = 500

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch let Network.Error.http(code: receiveStatusCode, description: _) {
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
}


// MARK: - Network Mocks

final class MockURLSession : URLSession {

    var mockDataTaskData: Data? = Data()
    var mockDataTaskError: Error? = nil
    var mockURLResponse: URLResponse = URLResponse()

    var mockAuthenticationChallenge: URLAuthenticationChallenge = URLAuthenticationChallenge()
    var mockAuthenticationCompletionHandler: Network.AuthenticationCompletionClosure = { _ in }

    private let _configuration: URLSessionConfiguration
    private let _delegate: URLSessionDelegate?
    private let _delegateQueue: OperationQueue

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

            strongSelf.delegate?.urlSession?(strongSelf,
                                             didReceive: strongSelf.mockAuthenticationChallenge,
                                             completionHandler: strongSelf.mockAuthenticationCompletionHandler)

            completionHandler(strongSelf.mockDataTaskData, strongSelf.mockURLResponse, strongSelf.mockDataTaskError)
        }

        return dataTask
    }
}

final class MockURLSessionDataTask : URLSessionDataTask {

    var resumeInvokedClosure: (() -> Void)?

    override func resume() {
        resumeInvokedClosure?()
    }
}
