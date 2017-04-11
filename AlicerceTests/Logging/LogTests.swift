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

    override func tearDown() {
        super.tearDown()
        Log.removeAllDestinations()
    }

    func testDestinationManagement() {

        let destination1 = Log.ConsoleDestination()
        let destination2 = Log.FileDestination(fileURL: URL(string: "https://www.google.com")!)
        let destination3 = Log.FileDestination(fileURL: URL(string: "https://www.amazon.com")!)

        Log.register(destination1)
        XCTAssertEqual(Log.destinationCount, 1)
        Log.register(destination1)
        XCTAssertEqual(Log.destinationCount, 1)
        Log.register(destination2)
        XCTAssertEqual(Log.destinationCount, 2)
        Log.register(destination3)
        XCTAssertEqual(Log.destinationCount, 3)
        Log.register(destination3)
        XCTAssertEqual(Log.destinationCount, 3)

        Log.unregister(destination1)
        XCTAssertEqual(Log.destinationCount, 2)
        Log.unregister(destination1)
        XCTAssertEqual(Log.destinationCount, 2)
    }

    func testErrorLoggingLevels() {

        let destination = Log.StringDestination()
        destination.minLevel = .error
        destination.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(destination.output, "error message")
    }

    func testWarningLoggingLevels() {

        let destination = Log.StringDestination()
        destination.minLevel = .warning
        destination.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(destination.output, "warning message\nerror message")
    }

    func testInfoLoggingLevels() {

        let destination = Log.StringDestination()
        destination.minLevel = .info
        destination.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(destination.output, "info message\nwarning message\nerror message")
    }

    func testDebugLoggingLevels() {

        let destination = Log.StringDestination()
        destination.minLevel = .debug
        destination.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(destination.output, "debug message\ninfo message\nwarning message\nerror message")
    }

    func testVerboseLoggingLevels() {

        let destination = Log.StringDestination()
        destination.minLevel = .verbose
        destination.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(destination.output, "verbose message\ndebug message\ninfo message\nwarning message\nerror message")
    }
}
