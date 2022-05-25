import XCTest
@testable import Alicerce

class ItemFormat_BuilderTestCase: XCTestCase {

    typealias Formatting = Log.ItemFormat.Formatting<String>

    // buildExpression

    func test_buildExpression_WithFormatComponent_ShouldBuildComponentFormatting() throws {

        try XCTAssertFormattingBuilder({ Log.ItemFormat.Value("test") }, returns: "test")
    }

    func test_buildExpression_WithKeyPath_ShouldBuildTextFormatting() throws {

        try XCTAssertFormattingBuilder({ \.message }, item: .dummy(message: "✉️"), returns: "✉️")
    }

    func test_buildExpression_WithString_ShouldBuildValueFormatting() throws {

        try XCTAssertFormattingBuilder({ "test" }, returns: "test")
    }

    func test_buildExpression_WithFormatting_ShouldBuildFormatting() throws {

        try XCTAssertFormattingBuilder({ .value("💪") }, returns: "💪")
    }

    func test_buildExpression_WithFormattingArray_ShouldBuildFormatting() throws {

        try XCTAssertFormattingBuilder({ [.value("🤜"), .value("🤛")] }, returns: "🤜🤛")
    }

    // buildOptional

    func test_buildOptional_WithTruePredicate_ShouldBuildBody() throws {

        let trueFlag = true

        try XCTAssertFormattingBuilder({ if trueFlag { .value("👍") } }, returns: "👍")
    }

    func test_buildOptional_WithFalsePredicate_ShouldNotBuildBody() throws {

        let falseFlag = false
        try XCTAssertFormattingBuilder({ if falseFlag { .value("👎") } }, returns: "")
    }

    // buildEither

    func test_buildEither_WithTruePredicate_ShouldBuildFirst() throws {

        let flag = true

        try XCTAssertFormattingBuilder(
            {
                if flag { .value("👍") }
                else { .value("👎") }
            },
            returns: "👍"
        )
    }

    func test_buildEither_WithFalsePredicate_ShouldBuildSecond() throws {

        let flag = false

        try XCTAssertFormattingBuilder(
            {
                if flag { .value("👍") }
                else { .value("👎") }
            },
            returns: "👎"
        )
    }

    // buildArray

    func test_buildArray_ShouldBuildFormatting() throws {

        try XCTAssertFormattingBuilder({ for text in ["💃", "🪩", "🕺"] { .value(text) } }, returns: "💃🪩🕺")
    }

    // buildLimitedAvailability

    func test_buildLimitedAvailability_WithTruePredicate_ShouldBuildFirstFormatting() throws {

        try XCTAssertFormattingBuilder(
            {
                if #available(iOS 10, *) { .value("👍") }
                else { .value("👎") }
            },
            returns: "👍"
        )
    }

    func test_buildLimitedAvailability_WithFalsePredicate_ShouldBuildSecondFormatting() throws {

        try XCTAssertFormattingBuilder(
            {
                if #available(iOS 1337, *) { .value("👍") }
                else { .value("👎") }
            },
            returns: "👎"
        )
    }

    // buildFinalResult

    func test_buildFinalResult_WithFormattingArray_ShouldBuildFormattingArray() throws {

        try XCTAssertFormattingArrayBuilder(
            {
                Formatting.value("🤜")
                Formatting.value("🤛")
            },
            returns: "🤜🤛"
        )
    }

    func test_buildFinalResult_WithFormatting_ShouldBuildFormatting() throws {

        try XCTAssertFormattingBuilder(
            {
                Formatting.value("🤜")
                Formatting.value("🤛")
            },
            returns: "🤜🤛"
        )
    }


    // MARK: - Helpers

    private func XCTAssertFormattingBuilder(
        @Log.ItemFormat.Builder _ formatting: () -> Formatting,
        item: Log.Item = .dummy(),
        initial: String = "",
        returns expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {

        var string = initial
        try formatting()(item, &string)
        XCTAssertEqual(string, expected, file: file, line: line)
    }

    private func XCTAssertFormattingArrayBuilder(
        @Log.ItemFormat.Builder _ formattingArray: () -> [Formatting],
        item: Log.Item = .dummy(),
        initial: String = "",
        returns expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {

        var string = initial
        try formattingArray().reduce(into: Formatting.empty, +=)(item, &string)
        XCTAssertEqual(string, expected, file: file, line: line)
    }
}
