//
//  FileProviderTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class FileProviderTests: XCTestCase {
    
    var documentsPath: String?
    var logfileURL: URL?
    var provider: FileProvider?
    
    override func setUp() {
        super.setUp()
        
        self.documentsPath = "file:///tmp/Log.log"
        self.logfileURL = URL(string: self.documentsPath!)!
        self.provider = FileProvider(fileURL: self.logfileURL!)
        self.provider!.clear()
        self.provider!.minLevel = .error
        self.provider!.formatter = LogItemStringFormatter(formatString: "$M")
    }
    
    override func tearDown() {
        super.tearDown()
        Log.removeAllProviders()
    }
    
    func testErrorLoggingLevels() {
        guard let provider = self.provider else { return }
        
        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")
        
        let content = self.logfileContent()
        XCTAssertEqual(content, "error message")
    }
    
    func testWarningLoggingLevels() {
        guard let provider = self.provider else { return }
        
        provider.minLevel = .warning

        Log.register(provider)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        let content = self.logfileContent()
        XCTAssertEqual(content, "warning message\nerror message")
    }
    
    //MARK:- private methods
    
    private func logfileContent() -> String {
        guard let logfileURL = self.logfileURL else { return "" }
        
        if let data = try? String(contentsOf: logfileURL) {
            return data
        }
        else {
            return ""
        }
    }
}
