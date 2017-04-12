//
//  ColoredLevelTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class ColoredLevelTests: XCTestCase {

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

    func testFileLogDestinationDefaultColoredLevels() {

        // preparation of the test subject

        let documentsPath = "file:///tmp/colored_default.log"
        let logfileURL = URL(string: documentsPath)!
        let formatter = Log.StringLogItemFormatter(formatString: "$C$M")
        let destination = Log.FileLogDestination(fileURL: logfileURL,
                                                 minLevel: .verbose,
                                                 formatter: formatter)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testFileLogDestinationDefaultColoredLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "📔  verbose message\n📗  debug message\n📘  info message\n📙  warning message\n📕  error message"
            let content = self.logfileContent(logfileURL: logfileURL)
            if (content == expected) {
                expectation.fulfill()
            }
        }

        // execute test

        destination.clear()
        Log.register(destination)
        Log.verbose("verbose message", completion: logWriteCompletion)
        Log.debug("debug message", completion: logWriteCompletion)
        Log.info("info message", completion: logWriteCompletion)
        Log.warning("warning message", completion: logWriteCompletion)
        Log.error("error message", completion: logWriteCompletion)
    }

    func testFileLogDestinationBashColoredLevels() {

        // preparation of the test subject

        let documentsPath = "file:///tmp/colored_bash.log"
        let logfileURL = URL(string: documentsPath)!
        let formatter = Log.StringLogItemFormatter(formatString: "$C$M",
                                                   levelFormatter: Log.BashLogItemLevelFormatter())
        let destination = Log.FileLogDestination(fileURL: logfileURL,
                                                 minLevel: .verbose,
                                                 formatter: formatter)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testFileLogDestinationBashColoredLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "\u{1B}[38;5;251mverbose message\n\u{1B}[38;5;35mdebug message\n\u{1B}[38;5;38minfo message\n\u{1B}[38;5;178mwarning message\n\u{1B}[38;5;197merror message"
            let content = self.logfileContent(logfileURL: logfileURL)
            if (content == expected) {
                expectation.fulfill()
            }
        }

        // execute test

        destination.clear()
        Log.register(destination)
        Log.verbose("verbose message", completion: logWriteCompletion)
        Log.debug("debug message", completion: logWriteCompletion)
        Log.info("info message", completion: logWriteCompletion)
        Log.warning("warning message", completion: logWriteCompletion)
        Log.error("error message", completion: logWriteCompletion)
    }

    //MARK:- private methods

    private func logfileContent(logfileURL: URL) -> String {

        return (try? String(contentsOf: logfileURL)) ?? ""
    }
}
