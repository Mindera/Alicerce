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
        Log.removeAllDestinations()
        documentsPath = nil
        logfileURL = nil
    }

    func testErrorLoggingLevels() {

        // preparation of the test subject

        let destination = Log.FileLogDestination(fileURL: self.logfileURL,
                                                 minLevel: .error,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"))

        // preparation of the test expectations

        let expectation = self.expectation(description: "testErrorLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "error message"
            let content = self.logfileContent()
            if content == expected {
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

    func testWarningLoggingLevels() {

        // preparation of the test subject

        let destination = Log.FileLogDestination(fileURL: self.logfileURL,
                                                 minLevel: .warning,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"))

        // preparation of the test expectations

        let expectation = self.expectation(description: "testErrorLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            let expected = "warning message\nerror message"
            let content = self.logfileContent()
            if content == expected {
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

    private func logfileContent() -> String {
        
        return (try? String(contentsOf: self.logfileURL)) ?? ""
    }
}
