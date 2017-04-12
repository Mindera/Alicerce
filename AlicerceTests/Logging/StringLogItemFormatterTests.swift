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
    
    func testDateFormatterCurrentTimeZone() {

        let dateFormat = "HH:mm:ss"
        let formatter = Log.StringLogItemFormatter(formatString: "$D\(dateFormat)")
        let destination = Log.StringLogDestination(minLevel: .verbose, formatter: formatter)

        // preparation of the test expectations

        let expectation = self.expectation(description: "testDateFormatterCurrentTimeZone")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        var writeCount = 0
        let logWriteCompletion: (LogDestination, Log.Item, Error?) -> Void = { (dest, item, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }

            writeCount += 1
            if (writeCount == 1) {

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = dateFormat
                let expected = dateFormatter.string(from: Date())

                XCTAssertEqual(destination.output, expected)
                expectation.fulfill()
            }
        }

        // execute test

        Log.register(destination)
        Log.verbose("verbose message", completion: logWriteCompletion)
    }
}
