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

    private var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()

        mockSession = MockURLSession()
    }

    override func tearDown() {
        super.tearDown()

        mockSession = nil
    }

    private let resource = Resource<Void>(path: "", method: .GET, parser: { _ in () })

    // MARK: - Success tests

    func testURLSession_WhenUsingConvenienceInit_ItShouldPopulateAllProperties() {
        let url = URL(string: "http://0.0.0.0")!
        let networkConfiguration = Network.Configuration(baseURL: url)

        let urlSessionStack = Network.URLSessionNetworkStack(configuration: networkConfiguration)

        // TODO: Replace with expectation
        urlSessionStack.fetch(resource: resource) { (inner: () throws -> Data) in
            do {
                let _ = try inner()
            } catch _ {}
        }
    }

    func testURLSession_WhenResponseIsSuccessful_ItShouldCallCompletionClosureWithData() {
        let baseURL = URL(string: "http://")!

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: 200,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        let mockData = "🎉".data(using: .utf8)
        mockSession.mockDataTaskData = mockData

        let network = Network.URLSessionNetworkStack(baseURL: baseURL, session: mockSession)

        network.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let data = try inner()

                XCTAssertEqual(data, mockData)
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }
        }
    }

    // MARK: - Error tests

    func testURLSession_WhenResponseHasAnError_ItShouldThrowReturnAnUrlError() {
        let baseURL = URL(string: "http://")!

        let statusCode = 500
        let mockError = NSError(domain: "☠️", code: statusCode, userInfo: nil)

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!
        mockSession.mockDataTaskError = mockError

        let network = Network.URLSessionNetworkStack(baseURL: baseURL, session: mockSession)

        network.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch let Network.Error.url(receivedError as NSError) {
                XCTAssertEqual(receivedError, mockError)
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }
        }
    }

    func testURLSession_WhenResponseIsNotHTTPKind_ItShouldThrowABadResponseError() {
        let baseURL = URL(string: "http://")!

        let network = Network.URLSessionNetworkStack(baseURL: baseURL, session: mockSession)

        network.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch Network.Error.badResponse {
                // 🤠 well done sir
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }
        }
    }

    func testURLSession_WhenResponseDontHasASuccessfulStatusCode_ItShouldThrowStatusCodeError() {
        let baseURL = URL(string: "http://")!

        let statusCode = 500

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!

        let network = Network.URLSessionNetworkStack(baseURL: baseURL, session: mockSession)

        network.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch let Network.Error.http(code: receiveStatusCode, description: _) {
                XCTAssertEqual(receiveStatusCode.rawValue, statusCode, "✅ received same sent status code from network 🤠")
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }
        }
    }

    func testURLSession_WhenResponseHasNoData_ItShouldThrowANoDataError() {
        let baseURL = URL(string: "http://")!

        let statusCode = 200

        mockSession.mockURLResponse = HTTPURLResponse(url: baseURL,
                                                      statusCode: statusCode,
                                                      httpVersion: nil,
                                                      headerFields: nil)!
        mockSession.mockDataTaskData = nil

        let network = Network.URLSessionNetworkStack(baseURL: baseURL, session: mockSession)

        network.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let _ = try inner()

                XCTFail("🔥 should throw an error 🤔")
            } catch Network.Error.noData {
                // 🤠 well done sir
            } catch {
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }
        }
    }
}


// MARK: - Network Mocks

final class MockURLSession : URLSession {

    var mockDataTaskData: Data? = Data()
    var mockDataTaskError: Error? = nil
    var mockURLResponse: URLResponse = URLResponse()

    override func dataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {

        let dataTask = MockURLSessionDataTask()

        dataTask.resumeInvokedClosure = { [weak self] in
            guard let strongSelf = self else { fatalError("🔥: `self` must be defined!") }

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
