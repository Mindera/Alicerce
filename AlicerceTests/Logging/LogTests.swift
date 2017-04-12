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

    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func tearDown() {
        super.tearDown()
        Log.removeAllDestinations()
    }

    func testDestinationManagement() {

        let destination1 = Log.ConsoleLogDestination()
        let destination2 = Log.FileLogDestination(fileURL: URL(string: "https://www.google.com")!)
        let destination3 = Log.FileLogDestination(fileURL: URL(string: "https://www.amazon.com")!)

        Log.register(destination1)
        XCTAssertEqual(Log.destinations.count, 1)
        Log.register(destination1)
        XCTAssertEqual(Log.destinations.count, 1)
        Log.register(destination2)
        XCTAssertEqual(Log.destinations.count, 2)
        Log.register(destination3)
        XCTAssertEqual(Log.destinations.count, 3)
        Log.register(destination3)
        XCTAssertEqual(Log.destinations.count, 3)

        Log.unregister(destination1)
        XCTAssertEqual(Log.destinations.count, 2)
        Log.unregister(destination1)
        XCTAssertEqual(Log.destinations.count, 2)
    }

    func testErrorLoggingLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .error, formatter: formatter)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testErrorLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "error message"
            if destination.output == expected {
                expectation.fulfill()
            }
        }

        // execute test

        Log.register(destination)
        Log.verbose("verbose message", completion: logWriteCompletion)
        Log.debug("debug message", completion: logWriteCompletion)
        Log.info("info message", completion: logWriteCompletion)
        Log.warning("warning message", completion: logWriteCompletion)
        Log.error("error message", completion: logWriteCompletion)
    }

    func testWarningLoggingLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .warning, formatter: formatter)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testWarningLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "warning message\nerror message"
            if destination.output == expected {
                expectation.fulfill()
            }
        }

        // execute test

        Log.register(destination)
        Log.verbose("verbose message", completion: logWriteCompletion)
        Log.debug("debug message", completion: logWriteCompletion)
        Log.info("info message", completion: logWriteCompletion)
        Log.warning("warning message", completion: logWriteCompletion)
        Log.error("error message", completion: logWriteCompletion)
    }

    func testInfoLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .info, formatter: formatter)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testInfoLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "info message\nwarning message\nerror message"
            if destination.output == expected {
                expectation.fulfill()
            }
        }

        // execute test

        Log.register(destination)
        Log.verbose("verbose message", completion: logWriteCompletion)
        Log.debug("debug message", completion: logWriteCompletion)
        Log.info("info message", completion: logWriteCompletion)
        Log.warning("warning message", completion: logWriteCompletion)
        Log.error("error message", completion: logWriteCompletion)
    }

    func testDebugLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .debug, formatter: formatter)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testDebugLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "debug message\ninfo message\nwarning message\nerror message"
            if destination.output == expected {
                expectation.fulfill()
            }
        }

        // execute test

        Log.register(destination)
        Log.verbose("verbose message", completion: logWriteCompletion)
        Log.debug("debug message", completion: logWriteCompletion)
        Log.info("info message", completion: logWriteCompletion)
        Log.warning("warning message", completion: logWriteCompletion)
        Log.error("error message", completion: logWriteCompletion)
    }

    func testVerboseLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .verbose, formatter: formatter)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testVerboseLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "verbose message\ndebug message\ninfo message\nwarning message\nerror message"
            if destination.output == expected {
                expectation.fulfill()
            }
        }

        // execute test

        Log.register(destination)
        Log.verbose("verbose message", completion: logWriteCompletion)
        Log.debug("debug message", completion: logWriteCompletion)
        Log.info("info message", completion: logWriteCompletion)
        Log.warning("warning message", completion: logWriteCompletion)
        Log.error("error message", completion: logWriteCompletion)
    }
}
