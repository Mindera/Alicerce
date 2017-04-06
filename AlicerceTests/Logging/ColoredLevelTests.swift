//
//  ColoredLevelTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class ColoredLevelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        Log.removeAllProviders()
    }
    
    func testFileProviderDefaultColoredLevels() {
        
        let documentsPath = "file:///tmp/colored_default.log"
        let logfileURL = URL(string: documentsPath)!
        let provider = FileProvider(fileURL: logfileURL)
        provider.clear()
        provider.minLevel = .verbose
        provider.formatter = LogItemStringFormatter(formatString: "$C$M")
        
        Log.register(provider)
        Log.verbose(message: "verbose message")
        Log.debug(message: "debug message")
        Log.info(message: "info message")
        Log.warning(message: "warning message")
        Log.error(message: "error message")
        
        let content = self.logfileContent(logfileURL: logfileURL)
        XCTAssertEqual(content, "📔  verbose message\n📗  debug message\n📘  info message\n📙  warning message\n📕  error message")
    }

    func testFileProviderBashColoredLevels() {
        
        let documentsPath = "file:///tmp/colored_bash.log"
        let logfileURL = URL(string: documentsPath)!
        let provider = FileProvider(fileURL: logfileURL)
        provider.clear()
        provider.minLevel = .verbose
        provider.formatter = LogItemStringFormatter(formatString: "$C$M", levelColorFormatter: LogItemLevelColorBashFormatter())
        
        Log.register(provider)
        Log.verbose(message: "verbose message")
        Log.debug(message: "debug message")
        Log.info(message: "info message")
        Log.warning(message: "warning message")
        Log.error(message: "error message")
        
        let content = self.logfileContent(logfileURL: logfileURL)
        XCTAssertEqual(content, "\u{1B}[38;5;251mverbose message\n\u{1B}[38;5;35mdebug message\n\u{1B}[38;5;38minfo message\n\u{1B}[38;5;178mwarning message\n\u{1B}[38;5;197merror message")
    }
    
    //MARK:- private methods
    
    private func logfileContent(logfileURL: URL) -> String {
        
        if let data = try? String(contentsOf: logfileURL) {
            return data
        }
        else {
            return ""
        }
    }
}
