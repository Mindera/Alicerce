//
//  LogItemJSONFormatterTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class LogItemJSONFormatterTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        Log.removeAllProviders()
    }

    func testLogItemJSONFormatter() {

        let provider = Log.StringProvider()
        provider.minLevel = .verbose
        provider.linefeed = ","
        provider.formatter = Log.ItemJSONFormatter()

        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        let jsonString = "[\(provider.output)]"
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
