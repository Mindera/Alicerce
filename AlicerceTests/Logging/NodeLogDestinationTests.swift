//
//  NodeLogDestinationTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

#if ALICERCE_LOG_SERVER_RUNNING

    class NodeLogDestinationTests: XCTestCase {

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

        func testErrorLoggingLevels() {

            // preparation of the test subject

            let formatter = Log.StringLogItemFormatter(levelFormatter: Log.BashLogItemLevelFormatter())
            let destination = Log.NodeLogDestination(serverURL: URL(string: "http://localhost:8080")!,
                                                     minLevel: .verbose,
                                                     formatter: formatter)

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

#endif
