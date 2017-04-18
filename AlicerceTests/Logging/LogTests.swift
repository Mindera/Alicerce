//
//  LogTests.swift
//  AlicerceTests
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class LogTests: XCTestCase {

    fileprivate let log = Log()
    fileprivate let queue = Log.Queue(label: "LogTests")
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func tearDown() {
        super.tearDown()
        log.removeAllDestinations()
    }

    func testDestinationManagement() {

        let destination1 = Log.ConsoleLogDestination()
        let destination2 = Log.FileLogDestination(fileURL: URL(string: "https://www.google.com")!)
        let destination3 = Log.FileLogDestination(fileURL: URL(string: "https://www.amazon.com")!)

        log.register(destination1)
        XCTAssertEqual(log.destinations.count, 1)
        log.register(destination1)
        XCTAssertEqual(log.destinations.count, 1)
        log.register(destination2)
        XCTAssertEqual(log.destinations.count, 2)
        log.register(destination3)
        XCTAssertEqual(log.destinations.count, 3)
        log.register(destination3)
        XCTAssertEqual(log.destinations.count, 3)

        log.unregister(destination1)
        XCTAssertEqual(log.destinations.count, 2)
        log.unregister(destination1)
        XCTAssertEqual(log.destinations.count, 2)
    }

    func testErrorLoggingLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .error,
                                                   formatter: formatter,
                                                   queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testErrorLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.async {
            let expected = "error message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.writtenItems, 1)
            expectation.fulfill()
        }
    }

    func testWarningLoggingLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .warning,
                                                   formatter: formatter,
                                                   queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testWarningLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.async {
            let expected = "warning message\nerror message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.writtenItems, 2)
            expectation.fulfill()
        }
    }

    func testInfoLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .info,
                                                   formatter: formatter,
                                                   queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testInfoLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.async {
            let expected = "info message\nwarning message\nerror message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.writtenItems, 3)
            expectation.fulfill()
        }
    }

    func testDebugLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .debug,
                                                   formatter: formatter,
                                                   queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testDebugLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.async {
            let expected = "debug message\ninfo message\nwarning message\nerror message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.writtenItems, 4)
            expectation.fulfill()
        }
    }

    func testVerboseLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .verbose,
                                                   formatter: formatter,
                                                   queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testVerboseLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.async {
            let expected = "verbose message\ndebug message\ninfo message\nwarning message\nerror message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.writtenItems, 5)
            expectation.fulfill()
        }
    }
}
