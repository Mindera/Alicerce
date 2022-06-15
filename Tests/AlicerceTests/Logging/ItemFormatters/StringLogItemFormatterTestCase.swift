import XCTest
@testable import Alicerce

class StringLogItemFormatterTestCase: XCTestCase {

    typealias Formatter = Log.StringLogItemFormatter
    typealias ItemFormatting = Log.ItemFormat.Formatting<String>

    private var formatter: Formatter!
    private var itemFormatting: ItemFormatting!

    override func setUp() {
        super.setUp()

        itemFormatting = Log.ItemFormat.string
        formatter = Log.StringLogItemFormatter { itemFormatting }
    }

    override func tearDown() {

        formatter = nil
        itemFormatting = nil

        super.tearDown()
    }

    func test_format_ShouldInvokeFormatting() throws {

        let itemFormattingExpectation = expectation(description: "itemFormatting")
        defer { waitForExpectations(timeout: 1) }

        itemFormatting = .init { _, _ in itemFormattingExpectation.fulfill() }
        formatter = Formatter { itemFormatting }

        _ = try formatter.format(item: .dummy())
    }

    func test_format_ShouldReturnFormattingOutput() throws {

        let item = Log.Item.dummy()
        let output = try formatter.format(item: item)

        var expected = ""
        try itemFormatting(item, &expected)

        XCTAssertEqual(output, expected)
    }
}
