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

        let provider = Log.NodeProvider(serverURL: URL(string: "http://localhost:8080")!)
        let enabled = false // enable this test when needed

        override func setUp() {
            super.setUp()
            self.provider.formatter = LogItemStringFormatter(
                levelFormatter: LogItemLevelBashFormatter())
        }

        override func tearDown() {
            super.tearDown()
            Log.removeAllProviders()
        }

        func testErrorLoggingLevels() {

            provider.minLevel = .verbose

            Log.register(provider)
            Log.verbose("verbose message")
            Log.debug("debug message")
            Log.info("info message")
            Log.warning("warning message")
            Log.error("error message")

            eventually(timeout: 0.5) {
                XCTAssertEqual(self.provider.logItemsSent, 5)
            }
        }
    }
    
#endif
