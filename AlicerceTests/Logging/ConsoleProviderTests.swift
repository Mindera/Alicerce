//
//  ConsoleProviderTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class ConsoleProviderTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        Log.removeAllProviders()
    }

    func testConsoleProvider() {

        let provider = Log.ConsoleProvider()
        provider.minLevel = .verbose

        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")
    }
}
