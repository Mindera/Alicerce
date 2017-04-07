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

    var documentsPath: String!
    var logfileURL: URL!
    var provider: Log.FileProvider!

    override func setUp() {
        super.setUp()

        self.documentsPath = "file:///tmp/Log.log"
        self.logfileURL = URL(string: self.documentsPath)!
        self.provider = Log.FileProvider(fileURL: self.logfileURL)
        self.provider.clear()
        self.provider.minLevel = .error
        self.provider.formatter = Log.ItemStringFormatter(formatString: "$M")
    }

    override func tearDown() {
        super.tearDown()
        Log.removeAllProviders()
        self.documentsPath = nil
        self.logfileURL = nil
        self.provider = nil
    }

    func testErrorLoggingLevels() {
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
        
        return (try? String(contentsOf: self.logfileURL)) ?? ""
    }
}
