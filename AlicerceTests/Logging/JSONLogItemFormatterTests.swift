//
//  JSONLogItemFormatterTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class JSONLogItemFormatterTests: XCTestCase {

    fileprivate let log = Log()
    fileprivate let queue = Log.Queue(label: "JSONLogItemFormatterTests")
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

    func testLogItemJSONFormatter() {

        // preparation of the test subject

        let destination = Log.StringLogDestination(minLevel: .verbose,
                                                   formatter: Log.JSONLogItemFormatter(),
                                                   queue: queue)
        destination.linefeed = ","

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

            let jsonString = "[\(destination.output)]"
            let jsonData = jsonString.data(using: .utf8)

            do {
                let obj = try JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments)

                guard let arr = obj as? [[String : Any]] else { XCTFail(); return }
                XCTAssertEqual(arr.count, 5)

                let verboseItem = arr.first
                XCTAssertNotNil(verboseItem)
                XCTAssertEqual(verboseItem!["level"] as? Int, Log.Level.verbose.rawValue)

                let errorItem = arr.last
                XCTAssertNotNil(errorItem)
                XCTAssertEqual(errorItem!["level"] as? Int, Log.Level.error.rawValue)
            }
            catch {
                XCTFail()
            }

            expectation.fulfill()
        }
    }
}
