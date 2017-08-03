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

    fileprivate var log: Log!
    fileprivate var queue: Log.Queue!
    fileprivate var documentsPath: String!
    fileprivate var logfileURL: URL!

    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func setUp() {
        super.setUp()

        log = Log(qos: .default)
        queue = Log.Queue(label: "FileLogDestinationTests")
        documentsPath = "file:///tmp/Log.log"
        logfileURL = URL(string: self.documentsPath)!
    }

    override func tearDown() {
        log = nil
        queue = nil
        documentsPath = nil
        logfileURL = nil

        super.tearDown()
    }

    func testErrorLoggingLevels() {

        // preparation of the test subject

        let destination = Log.FileLogDestination(fileURL: self.logfileURL,
                                                 minLevel: .error,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"),
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
            let expected = "error message"
            let content = self.logfileContent()
            XCTAssertEqual(content, expected)
            XCTAssertEqual(destination.writtenItems, 1)
        }
    }

    func testWarningLoggingLevels() {

        // preparation of the test subject

        let destination = Log.FileLogDestination(fileURL: self.logfileURL,
                                                 minLevel: .warning,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"),
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
            let expected = "warning message\nerror message"
            let content = self.logfileContent()
            XCTAssertEqual(content, expected)
            XCTAssertEqual(destination.writtenItems, 2)
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
