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
        queue = Log.Queue(label: "StringLogItemFormatterTests")
    }

    override func tearDown() {
        log = nil
        queue = nil

        super.tearDown()
    }

    func testDateFormatterCurrentTimeZone() {

        let dateFormat = "HH:mm:ss"
        let formatter = Log.StringLogItemFormatter(formatString: "$D\(dateFormat)")
        let destination = Log.StringLogDestination(minLevel: .verbose,
                                                   formatter: formatter,
                                                   queue: queue)

        // execute test

        log.register(destination)
        log.verbose("verbose message")

        queue.dispatchQueue.sync {

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = dateFormat
            let expected = dateFormatter.string(from: Date())

            XCTAssertEqual(destination.output.split(separator: "\n").count, 1)
            XCTAssertEqual(destination.output, expected)
        }
    }
}
