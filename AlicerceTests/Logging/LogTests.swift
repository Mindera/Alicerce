//
//  LogTests.swift
//  AlicerceTests
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class LogTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        super.tearDown()
        Log.removeAllProviders()
    }
    
    func testProviderManagement() {
        
        let provider1 = ConsoleProvider()
        let provider2 = FileProvider(fileURL: URL(string: "https://www.google.com")!)
        let provider3 = FileProvider(fileURL: URL(string: "https://www.amazon.com")!)
        
        Log.register(provider1)
        XCTAssertEqual(Log.providerCount, 1)
        Log.register(provider1)
        XCTAssertEqual(Log.providerCount, 1)
        Log.register(provider2)
        XCTAssertEqual(Log.providerCount, 2)
        Log.register(provider3)
        XCTAssertEqual(Log.providerCount, 3)
        Log.register(provider3)
        XCTAssertEqual(Log.providerCount, 3)
        
        Log.unregister(provider1)
        XCTAssertEqual(Log.providerCount, 2)
        Log.unregister(provider1)
        XCTAssertEqual(Log.providerCount, 2)
    }
    
    func testErrorLoggingLevels() {
        
        let provider = StringProvider()
        provider.minLevel = .error
        provider.formatter = LogItemStringFormatter(formatString: "$M")
        
        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(provider.output, "error message")
    }
    
    func testWarningLoggingLevels() {
        
        let provider = StringProvider()
        provider.minLevel = .warning
        provider.formatter = LogItemStringFormatter(formatString: "$M")
        
        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        XCTAssertEqual(provider.output, "warning message\nerror message")
    }

    func testInfoLoggingLevels() {
        
        let provider = StringProvider()
        provider.minLevel = .info
        provider.formatter = LogItemStringFormatter(formatString: "$M")
        
        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")
        
        XCTAssertEqual(provider.output, "info message\nwarning message\nerror message")
    }
    
    func testDebugLoggingLevels() {
        
        let provider = StringProvider()
        provider.minLevel = .debug
        provider.formatter = LogItemStringFormatter(formatString: "$M")
        
        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")
        
        XCTAssertEqual(provider.output, "debug message\ninfo message\nwarning message\nerror message")
    }
    
    func testVerboseLoggingLevels() {
        
        let provider = StringProvider()
        provider.minLevel = .verbose
        provider.formatter = LogItemStringFormatter(formatString: "$M")
        
        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")
        
        XCTAssertEqual(provider.output, "verbose message\ndebug message\ninfo message\nwarning message\nerror message")
    }
}
