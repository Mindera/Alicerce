import XCTest
@testable import Alicerce

class DefaultLogLevelFormatterTestCase: XCTestCase {

    private var formatter: Log.DefaultLogLevelFormatter!
    
    override func setUp() {
        super.setUp()

        formatter = Log.DefaultLogLevelFormatter()
    }
    
    override func tearDown() {
        formatter = nil

        super.tearDown()
    }

    func testColorEscape_ShouldReturnCorrectValue() {
        XCTAssertEqual(formatter.colorEscape, "")
    }

    func testColorReset_ShouldReturnCorrectValue() {
        XCTAssertEqual(formatter.colorReset, "")
    }

    func testColorString_ShouldReturnCorrectValue() {
        XCTAssertEqual(formatter.colorString(for: .verbose), "📓")
        XCTAssertEqual(formatter.colorString(for: .debug), "📗")
        XCTAssertEqual(formatter.colorString(for: .info), "📘")
        XCTAssertEqual(formatter.colorString(for: .warning), "📒")
        XCTAssertEqual(formatter.colorString(for: .error), "📕")
    }

    func testLabelString_ShouldReturnCorrectValue() {
        XCTAssertEqual(formatter.labelString(for: .verbose), "VERBOSE")
        XCTAssertEqual(formatter.labelString(for: .debug), "DEBUG")
        XCTAssertEqual(formatter.labelString(for: .info), "INFO")
        XCTAssertEqual(formatter.labelString(for: .warning), "WARNING")
        XCTAssertEqual(formatter.labelString(for: .error), "ERROR")
    }
}
