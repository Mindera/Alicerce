import XCTest
@testable import Alicerce


class BashLogItemLevelFormatterTestCase: XCTestCase {

    private var formatter: Log.BashLogLevelFormatter!

    override func setUp() {
        super.setUp()

        formatter = Log.BashLogLevelFormatter()
    }

    override func tearDown() {
        formatter = nil

        super.tearDown()
    }

    func testColorEscape_ShouldReturnCorrectValue() {
        XCTAssertEqual(formatter.colorEscape, "\u{001b}[38;5;")
    }

    func testColorReset_ShouldReturnCorrectValue() {
        XCTAssertEqual(formatter.colorReset, "\u{001b}[0m")
    }

    func testColorString_ShouldReturnCorrectValue() {
        XCTAssertEqual(formatter.colorString(for: .verbose), "251m")
        XCTAssertEqual(formatter.colorString(for: .debug), "35m")
        XCTAssertEqual(formatter.colorString(for: .info), "38m")
        XCTAssertEqual(formatter.colorString(for: .warning), "178m")
        XCTAssertEqual(formatter.colorString(for: .error), "197m")
    }

    func testLabelString_ShouldReturnCorrectValue() {
        XCTAssertEqual(formatter.labelString(for: .verbose), "VERBOSE")
        XCTAssertEqual(formatter.labelString(for: .debug), "DEBUG")
        XCTAssertEqual(formatter.labelString(for: .info), "INFO")
        XCTAssertEqual(formatter.labelString(for: .warning), "WARNING")
        XCTAssertEqual(formatter.labelString(for: .error), "ERROR")
    }
}
