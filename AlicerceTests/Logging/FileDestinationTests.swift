//
//  FileDestinationTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class FileDestinationTests: XCTestCase {

    var documentsPath: String!
    var logfileURL: URL!
    var destination: Log.FileDestination!

    override func setUp() {
        super.setUp()

        documentsPath = "file:///tmp/Log.log"
        logfileURL = URL(string: self.documentsPath)!
        destination = Log.FileDestination(fileURL: self.logfileURL)
        destination.clear()
        destination.minLevel = .error
        destination.formatter = Log.ItemStringFormatter(formatString: "$M")
    }

    override func tearDown() {
        super.tearDown()
        Log.removeAllDestinations()
        documentsPath = nil
        logfileURL = nil
        destination = nil
    }

    func testErrorLoggingLevels() {
        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        let content = self.logfileContent()
        XCTAssertEqual(content, "error message")
    }

    func testWarningLoggingLevels() {

        destination.minLevel = .warning

        Log.register(destination)
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
