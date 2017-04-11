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

    override func tearDown() {
        super.tearDown()
        Log.removeAllDestinations()
    }

    func testConsoleLogDestination() {

        let destination = Log.ConsoleLogDestination(minLevel: .verbose)

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")
    }
}
