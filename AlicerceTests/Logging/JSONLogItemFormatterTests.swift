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

    override func tearDown() {
        super.tearDown()
        Log.removeAllDestinations()
    }

    func testLogItemJSONFormatter() {

        let destination = Log.StringLogDestination(minLevel: .verbose, formatter: Log.JSONLogItemFormatter())
        destination.linefeed = ","

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

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
    }
}
