import XCTest
@testable import Alicerce

class ItemFormat_FormattingTestCase: XCTestCase {

    typealias Formatting = Log.ItemFormat.Formatting<String>

    // MARK: - Data

    func test_plusOperator_ShouldChainOperations() throws {

        let lhs = Formatting { $1 += "👉" }
        let rhs = Formatting { $1 += "👈" }

        try XCTAssertFormatting(lhs + rhs, returns: "👉👈")
    }

    func test_plusEqualOperator_ShouldChainOperations() throws {

        var lhs = Formatting { $1 += "👉" }
        let rhs = Formatting { $1 += "👈" }
        lhs += rhs

        try XCTAssertFormatting(lhs, returns: "👉👈")
    }

    func test_empty_ShouldNotChangeString() throws {

        var string = ""
        try Formatting.empty(.dummy(), &string)

        try XCTAssertFormatting(.empty, returns: "")
    }

    func test_keyPath_ShouldAppendValue() throws {

        let item = Log.Item.dummy()
        let kp = \Log.Item.file

        try XCTAssertFormatting(.keyPath(kp), item: item, returns: item[keyPath: kp])
    }

    func test_value_ShouldAppendValue() throws {

        let text = "test"

        try XCTAssertFormatting(.value(text), returns: text)
    }

    func test_formatItem_String_ShouldPassInEmptyString() throws {

        let empty = ""
        let output = try Formatting { _, output in XCTAssertEqual(output, empty) }.formatItem(.dummy())
        XCTAssertEqual(output, empty)
    }

    // MARK: - Data

    func test_formatItem_Data_ShouldPassInEmptyData() throws {

        typealias Formatting = Log.ItemFormat.Formatting<Data>

        let empty = Data()
        let output = try Formatting { _, output in XCTAssertEqual(output, empty) }.formatItem(.dummy())
        XCTAssertEqual(output, empty)
    }

    // MARK: - Helpers

    private func XCTAssertFormatting(
        _ formatting: Formatting,
        item: Log.Item = .dummy(),
        initial: String = "",
        returns expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {

        var string = initial
        try formatting(item, &string)
        XCTAssertEqual(string, expected, file: file, line: line)
    }
}
