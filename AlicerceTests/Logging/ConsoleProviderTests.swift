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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        Log.removeAllProviders()
    }
    
    func testConsoleProvider() {
        
        let provider = ConsoleProvider()
        provider.minLevel = .verbose
        
        Log.register(provider)
        Log.verbose(message: "verbose message")
        Log.debug(message: "debug message")
        Log.info(message: "info message")
        Log.warning(message: "warning message")
        Log.error(message: "error message")
    }
}
