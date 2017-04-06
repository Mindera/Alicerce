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
        
        let provider = StringProvider()
        provider.minLevel = .verbose
        provider.linefeed = ","
        provider.formatter = LogItemJSONFormatter()
        
        Log.register(provider)
        Log.verbose(message: "verbose message")
        Log.debug(message: "debug message")
        Log.info(message: "info message")
        Log.warning(message: "warning message")
        Log.error(message: "error message")
        
        let jsonString = "[\(provider.output)]"
        let jsonData = jsonString.data(using: .utf8)
        
        if let obj = try? JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments) {
            let arr = obj as? Array<Dictionary<String, Any>>
            XCTAssertNotNil(arr)
            XCTAssertEqual(arr!.count, 5)
            
            let verboseItem = arr!.first
            XCTAssertNotNil(verboseItem)
            XCTAssertEqual(verboseItem!["level"] as? Int, Log.Level.verbose.rawValue)
            
            let errorItem = arr!.last
            XCTAssertNotNil(errorItem)
            XCTAssertEqual(errorItem!["level"] as? Int, Log.Level.error.rawValue)
        }
        else {
            XCTAssert(false, "failed to transform the generated JSON string to an native object.")
        }
    }
}
