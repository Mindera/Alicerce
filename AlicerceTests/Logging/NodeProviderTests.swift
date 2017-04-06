//
//  FileProviderTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

#if ALICERCE_LOG_SERVER_RUNNING

class NodeProviderTests: XCTestCase {
    
    let provider = NodeProvider(serverURL: URL(string: "http://localhost:8080")!)
    let enabled = false // enable this test when needed
    
    override func setUp() {
        super.setUp()
        self.provider.formatter = LogItemStringFormatter(
            formatString: LogItemStringFormatter.defaultFormatString,
            levelColorFormatter: LogItemLevelColorBashFormatter())
    }
    
    override func tearDown() {
        super.tearDown()
        Log.removeAllProviders()
    }
    
    func testErrorLoggingLevels() {
        
        provider.minLevel = .verbose
        
        Log.register(provider: provider)
        Log.verbose(message: "verbose message")
        Log.debug(message: "debug message")
        Log.info(message: "info message")
        Log.warning(message: "warning message")
        Log.error(message: "error message")
        
        eventually(timeout: 0.5) {
            XCTAssertEqual(self.provider.logItemsSent, 5)
        }
    }
}

#endif
