//
//  FileLogDestinationTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class FileLogDestinationTests: XCTestCase {

    fileprivate let log = Log()
    fileprivate let queue = Log.Queue(label: "FileLogDestinationTests")
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    var documentsPath: String!
    var logfileURL: URL!

    override func setUp() {
        super.setUp()

        documentsPath = "file:///tmp/Log.log"
        logfileURL = URL(string: self.documentsPath)!
    }

    override func tearDown() {
        super.tearDown()
        log.errorClosure = nil
        log.removeAllDestinations()
        documentsPath = nil
        logfileURL = nil
    }

    func testErrorLoggingLevels() {

        // preparation of the test subject

        let destination = Log.FileLogDestination(fileURL: self.logfileURL,
                                                 minLevel: .error,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"),
                                                 queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testErrorLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        destination.clear()
        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.async { [weak self] in
            guard let strongSelf = self else { return }

            let expected = "error message"
            let content = strongSelf.logfileContent()
            XCTAssertEqual(content, expected)
            XCTAssertEqual(destination.writtenItems, 1)
            expectation.fulfill()
        }
    }

    func testWarningLoggingLevels() {

        // preparation of the test subject

        let destination = Log.FileLogDestination(fileURL: self.logfileURL,
                                                 minLevel: .warning,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"),
                                                 queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testWarningLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        destination.clear()
        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.async { [weak self] in
            guard let strongSelf = self else { return }

            let expected = "warning message\nerror message"
            let content = strongSelf.logfileContent()
            XCTAssertEqual(content, expected)
            XCTAssertEqual(destination.writtenItems, 2)
            expectation.fulfill()
        }
    }

    func testErrorClosureIsBeingCalled() {

        // preparation of the test subject

        let failingLogfileURL = URL(string: "file:///non_existing_folder/Log.log")!
        let destination = Log.FileLogDestination(fileURL: failingLogfileURL,
                                                 minLevel: .error,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"),
                                                 queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testErrorClosureIsBeingCalled")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        log.errorClosure = { (destination: LogDestination, item:Log.Item, error: Error) -> () in
            expectation.fulfill()
        }

        destination.clear()
        log.register(destination)
        log.error("verbose message")
    }


    //MARK:- private methods

    private func logfileContent() -> String {
        
        return (try? String(contentsOf: self.logfileURL)) ?? ""
    }
}
