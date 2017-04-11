//
//  NodeLogDestinationTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

#if ALICERCE_LOG_SERVER_RUNNING

    class NodeLogDestinationTests: XCTestCase {

        override func tearDown() {
            super.tearDown()
            Log.removeAllDestinations()
        }

        func testErrorLoggingLevels() {

            let formatter = Log.StringLogItemFormatter(levelFormatter: Log.BashLogItemLevelFormatter())
            let destination = Log.NodeLogDestination(serverURL: URL(string: "http://localhost:8080")!,
                                                     minLevel: .verbose,
                                                     formatter: formatter)

            Log.register(destination)
            Log.verbose("verbose message")
            Log.debug("debug message")
            Log.info("info message")
            Log.warning("warning message")
            Log.error("error message")

            eventually(timeout: 0.5) {
                XCTAssertEqual(destination.logItemsSent, 5)
            }
        }
}

#endif
