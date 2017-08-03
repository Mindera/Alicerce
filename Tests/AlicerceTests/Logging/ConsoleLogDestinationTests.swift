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
        queue = Log.Queue(label: "ConsoleLogDestinationsTests")
    }

    override func tearDown() {
        log = nil
        queue = nil

        super.tearDown()
    }

    func testConsoleLogDestination() {

        // preparation of the test subject

        let destination = Log.ConsoleLogDestination(minLevel: .verbose, queue: queue)

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {
            XCTAssertEqual(destination.writtenItems, 5)
        }
    }
}
