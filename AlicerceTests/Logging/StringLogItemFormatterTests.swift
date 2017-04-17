//
//  StringLogItemFormatterTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 12/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class StringLogItemFormatterTests: XCTestCase {

    fileprivate let log = Log()
    fileprivate let queue = Log.Queue(label: "StringLogItemFormatterTests")
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

    func testDateFormatterCurrentTimeZone() {

        let dateFormat = "HH:mm:ss"
        let formatter = Log.StringLogItemFormatter(formatString: "$D\(dateFormat)")
        let destination = Log.StringLogDestination(minLevel: .verbose,
                                                   formatter: formatter,
                                                   queue: queue)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testDateFormatterCurrentTimeZone")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // execute test

        log.register(destination)
        log.verbose("verbose message")

        queue.dispatchQueue.async {

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = dateFormat
            let expected = dateFormatter.string(from: Date())

            XCTAssertEqual(destination.writtenItems, 1)
            XCTAssertEqual(destination.output, expected)
            expectation.fulfill()
        }
    }
}
