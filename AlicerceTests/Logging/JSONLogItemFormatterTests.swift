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

    func testLogItemJSONFormatter() {

        // preparation of the test subject

        let destination = Log.StringLogDestination(minLevel: .verbose,
                                                   formatter: Log.JSONLogItemFormatter(),
                                                   dispatchQueue: DispatchQueue.main)
        destination.linefeed = ","

        // preparation of the test expectations

        let expectation = self.expectation(description: "testErrorLoggingLevels")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        var writeCount = 0
        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            writeCount += 1
            if writeCount == 5 {

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
                    expectation.fulfill()
                }
                catch {
                    XCTFail()
                }
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
