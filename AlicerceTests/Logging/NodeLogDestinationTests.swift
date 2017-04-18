//
//  NodeLogDestinationTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

private final class MockURLSession : URLSession {
    // TODO: use the Result<Data, Error> enum, instead of 'mockError' once available in Alicerce.
    var mockURLResponse: URLResponse = URLResponse()
    var mockError: Error? = nil
    var mockValidationClosure: ((URLRequest) -> ())? = nil

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {

        let dataTask = MockURLSessionDataTask()

        dataTask.resumeInvokedClosure = { [weak self] in
            guard let strongSelf = self else { fatalError("🔥: `self` must be defined!") }
            strongSelf.mockValidationClosure?(request)
            if let error = strongSelf.mockError {
                completionHandler(nil, strongSelf.mockURLResponse, error)
            }
            else {
                completionHandler(nil, strongSelf.mockURLResponse, nil)
            }
        }

        return dataTask
    }
}

private final class MockURLSessionDataTask : URLSessionDataTask {

    var resumeInvokedClosure: (() -> Void)?

    override func resume() {
        resumeInvokedClosure?()
    }
}

class NodeLogDestinationTests: XCTestCase {

    fileprivate let log = Log()
    fileprivate let queue = Log.Queue(label: "NodeLogDestinationTests")
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func tearDown() {
        super.tearDown()
        log.errorClosure = nil
        log.removeAllDestinations()
    }

    func testNodeLogHappyPath() {

        // preparation of the test expectations

        let expectation = self.expectation(description: "testNodeLogHappyPath")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // preparation of the test subject

        let mockedSession = MockURLSession()
        mockedSession.mockValidationClosure = { request in

            let bodyString = String(data: request.httpBody!, encoding: .utf8)
            XCTAssertEqual(bodyString, "verbose message")
            expectation.fulfill()
        }

        let formatter = Log.StringLogItemFormatter(formatString:"$M",
                                                   levelFormatter: Log.BashLogItemLevelFormatter())

        let destination = Log.NodeLogDestination(serverURL: URL(string: "http://localhost:8080")!,
                                                 minLevel: .verbose,
                                                 formatter: formatter,
                                                 urlSession: mockedSession,
                                                 queue: queue)

        // execute test

        log.register(destination)
        log.verbose("verbose message")
    }

    func testNodeLogFailurePath() {

        // preparation of the test expectations

        let expectation = self.expectation(description: "testNodeLogFailurePath")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // preparation of the test subject

        let mockedSession = MockURLSession()
        mockedSession.mockError = NSError(domain: "mock", code: 1, userInfo: nil)

        let formatter = Log.StringLogItemFormatter(formatString:"$M",
                                                   levelFormatter: Log.BashLogItemLevelFormatter())

        let destination = Log.NodeLogDestination(serverURL: URL(string: "http://localhost:8080")!,
                                                 minLevel: .verbose,
                                                 formatter: formatter,
                                                 urlSession: mockedSession,
                                                 queue: queue)

        log.errorClosure = { (destination: LogDestination, item:Log.Item, error: Error) -> () in
            expectation.fulfill()
        }

        // execute test

        log.register(destination)
        log.verbose("verbose message")
    }
}
