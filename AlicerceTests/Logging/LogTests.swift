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
        Log.removeAllProviders()
    }

    func testProviderManagement() {

        let provider1 = Log.ConsoleProvider()
        let provider2 = Log.FileProvider(fileURL: URL(string: "https://www.google.com")!)
        let provider3 = Log.FileProvider(fileURL: URL(string: "https://www.amazon.com")!)

        Log.register(provider1)
        XCTAssertEqual(Log.providerCount, 1)
        Log.register(provider1)
        XCTAssertEqual(Log.providerCount, 1)
        Log.register(provider2)
        XCTAssertEqual(Log.providerCount, 2)
        Log.register(provider3)
        XCTAssertEqual(Log.providerCount, 3)
        Log.register(provider3)
        XCTAssertEqual(Log.providerCount, 3)

        Log.unregister(provider1)
        XCTAssertEqual(Log.providerCount, 2)
        Log.unregister(provider1)
        XCTAssertEqual(Log.providerCount, 2)
    }

    func testErrorLoggingLevels() {

        let provider = Log.StringProvider()
        provider.minLevel = .error
        provider.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(provider.output, "error message")
    }

    func testWarningLoggingLevels() {

        let provider = Log.StringProvider()
        provider.minLevel = .warning
        provider.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(provider.output, "warning message\nerror message")
    }

    func testInfoLoggingLevels() {

        let provider = Log.StringProvider()
        provider.minLevel = .info
        provider.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(provider.output, "info message\nwarning message\nerror message")
    }

    func testDebugLoggingLevels() {

        let provider = Log.StringProvider()
        provider.minLevel = .debug
        provider.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(provider.output, "debug message\ninfo message\nwarning message\nerror message")
    }

    func testVerboseLoggingLevels() {

        let provider = Log.StringProvider()
        provider.minLevel = .verbose
        provider.formatter = Log.ItemStringFormatter(formatString: "$M")

        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(provider.output, "verbose message\ndebug message\ninfo message\nwarning message\nerror message")
    }
}
