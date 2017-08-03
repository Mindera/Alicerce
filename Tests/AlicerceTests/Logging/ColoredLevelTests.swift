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
        queue = Log.Queue(label: "ColoredLevelTests")

    }

    override func tearDown() {
        log = nil
        queue = nil

        super.tearDown()
    }

    func testFileLogDestinationDefaultColoredLevels() {

        // preparation of the test subject

        let documentsPath = "file:///tmp/colored_default.log"
        let logfileURL = URL(string: documentsPath)!
        let formatter = Log.StringLogItemFormatter(formatString: "$C$M")
        let destination = Log.FileLogDestination(fileURL: logfileURL,
                                                 minLevel: .verbose,
                                                 formatter: formatter,
                                                 queue: queue)

        // execute test

        destination.clear()
        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {
            let expected = "📓verbose message\n📗debug message\n📘info message\n📒warning message\n📕error message"
            let content = self.logfileContent(logfileURL: logfileURL)
            XCTAssertEqual(content, expected)
            XCTAssertEqual(destination.writtenItems, 5)
        }
    }

    func testFileLogDestinationBashColoredLevels() {

        // preparation of the test subject

        let documentsPath = "file:///tmp/colored_bash.log"
        let logfileURL = URL(string: documentsPath)!
        let formatter = Log.StringLogItemFormatter(formatString: "$C$M",
                                                   levelFormatter: Log.BashLogItemLevelFormatter())
        let destination = Log.FileLogDestination(fileURL: logfileURL,
                                                 minLevel: .verbose,
                                                 formatter: formatter,
                                                 queue: queue)

        // execute test

        destination.clear()
        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {
            let expected = "\u{1B}[38;5;251mverbose message\n\u{1B}[38;5;35mdebug message\n\u{1B}[38;5;38minfo message\n\u{1B}[38;5;178mwarning message\n\u{1B}[38;5;197merror message"
            let content = self.logfileContent(logfileURL: logfileURL)
            XCTAssertEqual(content, expected)
            XCTAssertEqual(destination.writtenItems, 5)
        }
    }

    //MARK:- private methods

    private func logfileContent(logfileURL: URL) -> String {

        return (try? String(contentsOf: logfileURL)) ?? ""
    }
}
