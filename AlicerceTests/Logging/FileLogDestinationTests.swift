//
//  FileLogDestinationTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class FileLogDestinationTests: XCTestCase {

    var documentsPath: String!
    var logfileURL: URL!

    override func setUp() {
        super.setUp()

        documentsPath = "file:///tmp/Log.log"
        logfileURL = URL(string: self.documentsPath)!
    }

    override func tearDown() {
        super.tearDown()
        Log.removeAllDestinations()
        documentsPath = nil
        logfileURL = nil
    }

    func testErrorLoggingLevels() {

        let destination = Log.FileLogDestination(fileURL: self.logfileURL,
                                                 minLevel: .error,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"))
        destination.clear()

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

        let destination = Log.FileLogDestination(fileURL: self.logfileURL,
                                                 minLevel: .warning,
                                                 formatter: Log.StringLogItemFormatter(formatString: "$M"))
        destination.clear()

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
