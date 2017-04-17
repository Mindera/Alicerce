//
//  ConsoleLogDestinationTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class ConsoleLogDestinationsTests: XCTestCase {

    fileprivate let log = Log()
    fileprivate let queue = Log.Queue(label: "ConsoleLogDestinationsTests")
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

    func testConsoleLogDestination() {

        // preparation of the test subject

        let destination = Log.ConsoleLogDestination(minLevel: .verbose,
                                                    queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testConsoleLogDestination")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.async {
            XCTAssertEqual(destination.writtenItems, 5)
            expectation.fulfill()
        }
    }
}
