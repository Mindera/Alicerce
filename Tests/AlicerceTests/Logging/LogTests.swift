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

    fileprivate var log: Log!
    fileprivate var queue: Log.Queue!
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func setUp() {
        super.setUp()

        log = Log(qos: .default)
        queue = Log.Queue(label: "LogTests")
    }

    override func tearDown() {
        log = nil
        queue = nil

        super.tearDown()
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

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {
            let expected = "error message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.output.split(separator: "\n").count, 1)
        }
    }

    func testWarningLoggingLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .warning,
                                                   formatter: formatter,
                                                   queue: queue)

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {
            let expected = "warning message\nerror message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.output.split(separator: "\n").count, 2)
        }
    }

    func testInfoLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .info,
                                                   formatter: formatter,
                                                   queue: queue)

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {
            let expected = "info message\nwarning message\nerror message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.output.split(separator: "\n").count, 3)
        }
    }

    func testDebugLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .debug,
                                                   formatter: formatter,
                                                   queue: queue)

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {
            let expected = "debug message\ninfo message\nwarning message\nerror message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.output.split(separator: "\n").count, 4)
        }
    }

    func testVerboseLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .verbose,
                                                   formatter: formatter,
                                                   queue: queue)

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {
            let expected = "verbose message\ndebug message\ninfo message\nwarning message\nerror message"
            XCTAssertEqual(destination.output, expected)
            XCTAssertEqual(destination.output.split(separator: "\n").count, 5)
        }
    }
}
