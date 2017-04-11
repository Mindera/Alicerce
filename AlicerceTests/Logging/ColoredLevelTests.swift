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

    override func tearDown() {
        super.tearDown()
        Log.removeAllDestinations()
    }

    func testFileLogDestinationDefaultColoredLevels() {

        let documentsPath = "file:///tmp/colored_default.log"
        let logfileURL = URL(string: documentsPath)!
        let destination = Log.FileLogDestination(fileURL: logfileURL)
        destination.clear()
        destination.minLevel = .verbose
        destination.formatter = Log.StringLogItemFormatter(formatString: "$C$M")

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        let content = self.logfileContent(logfileURL: logfileURL)
        XCTAssertEqual(content, "📔  verbose message\n📗  debug message\n📘  info message\n📙  warning message\n📕  error message")
    }

    func testFileLogDestinationBashColoredLevels() {

        let documentsPath = "file:///tmp/colored_bash.log"
        let logfileURL = URL(string: documentsPath)!
        let destination = Log.FileLogDestination(fileURL: logfileURL)
        destination.clear()
        destination.minLevel = .verbose
        destination.formatter = Log.StringLogItemFormatter(formatString: "$C$M", levelFormatter: Log.BashLogItemLevelFormatter())

        Log.register(destination)
        Log.verbose("verbose message")
        Log.debug("debug message")
        Log.info("info message")
        Log.warning("warning message")
        Log.error("error message")

        let content = self.logfileContent(logfileURL: logfileURL)
        XCTAssertEqual(content, "\u{1B}[38;5;251mverbose message\n\u{1B}[38;5;35mdebug message\n\u{1B}[38;5;38minfo message\n\u{1B}[38;5;178mwarning message\n\u{1B}[38;5;197merror message")
    }

    //MARK:- private methods

    private func logfileContent(logfileURL: URL) -> String {

        return (try? String(contentsOf: logfileURL)) ?? ""
    }
}
