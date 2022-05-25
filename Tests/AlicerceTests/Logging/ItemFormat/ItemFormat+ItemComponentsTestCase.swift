import XCTest
@testable import Alicerce

class ItemFormat_ItemComponentsTestCase: XCTestCase {

    typealias Formatting = Log.ItemFormat.Formatting<String>

    typealias Timestamp = Log.ItemFormat.Timestamp
    typealias Module = Log.ItemFormat.Module
    typealias EmojiLevel = Log.ItemFormat.EmojiLevel
    typealias Level = Log.ItemFormat.Level
    typealias Message = Log.ItemFormat.Message
    typealias Thread = Log.ItemFormat.Thread
    typealias Queue = Log.ItemFormat.Queue
    typealias File = Log.ItemFormat.File
    typealias Line = Log.ItemFormat.Line
    typealias Function = Log.ItemFormat.Function
    typealias Bash = Log.ItemFormat.Bash

    // MARK: - Timestamp

    func test_Timestamp_WithClosureFormat_ShouldFormatTimestampAndAppendText() throws {

        let item = Log.Item.dummy()
        let dateFormat: (Date) -> String = ISO8601DateFormatter().string(from:)
        let component = Timestamp(format: dateFormat)

        try XCTAssertComponent(component, item: item, returns: dateFormat(item.timestamp))
    }

    func test_Timestamp_WithDateFormatter_ShouldFormatTimestampAndAppendText() throws {

        let item = Log.Item.dummy()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"

        let component = Timestamp(dateFormatter: dateFormatter)

        try XCTAssertComponent(component, item: item, returns: dateFormatter.string(from: item.timestamp))
    }

    // MARK: - Module

    func test_Module_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Module(), item: .dummy(module: "🙋"), returns: "🙋")
        try XCTAssertComponent(Module(default: "🤷"), item: .dummy(module: nil), returns: "🤷")
    }

    // MARK: - EmojiLevel

    func test_EmojiLevel_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(EmojiLevel(), item: .dummy(level: .verbose), returns: "📓")
        try XCTAssertComponent(EmojiLevel(), item: .dummy(level: .debug), returns: "📗")
        try XCTAssertComponent(EmojiLevel(), item: .dummy(level: .info), returns: "📘")
        try XCTAssertComponent(EmojiLevel(), item: .dummy(level: .warning), returns: "📒")
        try XCTAssertComponent(EmojiLevel(), item: .dummy(level: .error), returns: "📕")
    }

    // MARK: - Level

    func test_Level_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Level(), item: .dummy(level: .verbose), returns: "verbose")
        try XCTAssertComponent(Level(), item: .dummy(level: .debug), returns: "debug")
        try XCTAssertComponent(Level(), item: .dummy(level: .info), returns: "info")
        try XCTAssertComponent(Level(), item: .dummy(level: .warning), returns: "warning")
        try XCTAssertComponent(Level(), item: .dummy(level: .error), returns: "error")
    }

    // MARK: - Message

    func test_message_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Message(), item: .dummy(message: "💌"), returns: "💌")
    }

    // MARK: - Thread

    func test_Thread_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Thread(), item: .dummy(thread: "🧵"), returns: "🧵")
    }

    // MARK: - Queue

    func test_Queue_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Queue(), item: .dummy(queue: "🚦"), returns: "🚦")
    }

    func test_File_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(
            File(includeExtension: true),
            item: .dummy(file: "file.ext"),
            returns: "file.ext"
        )

        try XCTAssertComponent(
            File(includeExtension: true),
            item: .dummy(file: "some/path/to/file.ext"),
            returns: "file.ext"
        )

        try XCTAssertComponent(
            File(includeExtension: true),
            item: .dummy(file: "/some/path/to/file.ext"),
            returns: "file.ext"
        )

        try XCTAssertComponent(
            File(includeExtension: true),
            item: .dummy(file: "/some/path/to/file"),
            returns: "file"
        )


        try XCTAssertComponent(
            File(includeExtension: false),
            item: .dummy(file: "file.ext"),
            returns: "file"
        )

        try XCTAssertComponent(
            File(includeExtension: false),
            item: .dummy(file: "some/path/to/file.ext"),
            returns: "file"
        )

        try XCTAssertComponent(
            File(includeExtension: false),
            item: .dummy(file: "/some/path/to/file.ext"),
            returns: "file"
        )

        try XCTAssertComponent(
            File(includeExtension: false),
            item: .dummy(file: "/some/path/to/file"),
            returns: "file"
        )

    }

    // MARK: - Function

    func test_Function_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Function(), item: .dummy(function: "🔢"), returns: "🔢")
    }

    // MARK: - Line

    func test_Line_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Line(), item: .dummy(line: 1337), returns: "1337")
    }

    // Bash

    func test_Bash_ColorEscape_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Bash.ColorEscape(), returns: "\u{001b}[38;5;")
    }

    func test_Bash_ColorReset_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Bash.ColorReset(), returns: "\u{001b}[0m")
    }

    func test_Bash_ColorLevel_ShouldAppendCorrectText() throws {

        try XCTAssertComponent(Bash.ColorLevel(), item: .dummy(level: .verbose), returns: "251m")
        try XCTAssertComponent(Bash.ColorLevel(), item: .dummy(level: .debug), returns: "35m")
        try XCTAssertComponent(Bash.ColorLevel(), item: .dummy(level: .info), returns: "38m")
        try XCTAssertComponent(Bash.ColorLevel(), item: .dummy(level: .warning), returns: "178m")
        try XCTAssertComponent(Bash.ColorLevel(), item: .dummy(level: .error), returns: "197m")
    }

    func test_Bash_ColorGroup_WithSeparator_ShouldWrapInBashColorForLevelAndIntersperseText() throws {

        let separator = "|"
        let textA = "A"
        let textB = "B"
        let textC = "C"

        let component = Bash.ColorGroup(separator: separator) {
            textA
            textB
            textC
        }

        let joined = [textA, textB, textC].joined(separator: "|")

        try XCTAssertComponent(
            component,
            item: .dummy(level: .verbose),
            returns: "\u{001b}[38;5;" + "251m" + joined + "\u{001b}[0m"
        )
        try XCTAssertComponent(
            component,
            item: .dummy(level: .debug),
            returns: "\u{001b}[38;5;" + "35m" + joined + "\u{001b}[0m"
        )
        try XCTAssertComponent(
            component,
            item: .dummy(level: .info),
            returns: "\u{001b}[38;5;" + "38m" + joined + "\u{001b}[0m"
        )
        try XCTAssertComponent(
            component,
            item: .dummy(level: .warning),
            returns: "\u{001b}[38;5;" + "178m" + joined + "\u{001b}[0m"
        )
        try XCTAssertComponent(
            component,
            item: .dummy(level: .error),
            returns: "\u{001b}[38;5;" + "197m" + joined + "\u{001b}[0m"
        )
    }

    func test_Bash_ColorGroup_WithNoSeparator_ShouldWrapInBashColorForLevel() throws {

        let textA = "A"
        let textB = "B"
        let textC = "C"

        let component = Bash.ColorGroup(separator: nil) {
            textA
            textB
            textC
        }

        let joined = [textA, textB, textC].joined(separator: "")

        try XCTAssertComponent(
            component,
            item: .dummy(level: .verbose),
            returns: "\u{001b}[38;5;" + "251m" + joined + "\u{001b}[0m"
        )
        try XCTAssertComponent(
            component,
            item: .dummy(level: .debug),
            returns: "\u{001b}[38;5;" + "35m" + joined + "\u{001b}[0m"
        )
        try XCTAssertComponent(
            component,
            item: .dummy(level: .info),
            returns: "\u{001b}[38;5;" + "38m" + joined + "\u{001b}[0m"
        )
        try XCTAssertComponent(
            component,
            item: .dummy(level: .warning),
            returns: "\u{001b}[38;5;" + "178m" + joined + "\u{001b}[0m"
        )
        try XCTAssertComponent(
            component,
            item: .dummy(level: .error),
            returns: "\u{001b}[38;5;" + "197m" + joined + "\u{001b}[0m"
        )
    }

    func test_Bash_ColorGroup_WithSeparatorAndSingleFormatting_ShouldWrapInBashColorForLevelAndNotIntersperseText() throws {

        let separator = "|"
        let test = "🎨"

        let component = Bash.ColorGroup(separator: separator) { test }

        try XCTAssertComponent(
            component,
            item: .dummy(level: .verbose),
            returns: "\u{001b}[38;5;" + "251m" + test + "\u{001b}[0m"
        )

        try XCTAssertComponent(
            component,
            item: .dummy(level: .debug),
            returns: "\u{001b}[38;5;" + "35m" + test + "\u{001b}[0m"
        )

        try XCTAssertComponent(
            component,
            item: .dummy(level: .info),
            returns: "\u{001b}[38;5;" + "38m" + test + "\u{001b}[0m"
        )

        try XCTAssertComponent(
            component,
            item: .dummy(level: .warning),
            returns: "\u{001b}[38;5;" + "178m" + test + "\u{001b}[0m"
        )

        try XCTAssertComponent(
            component,
            item: .dummy(level: .error),
            returns: "\u{001b}[38;5;" + "197m" + test + "\u{001b}[0m"
        )

    }

    // MARK: - Helpers

    private func XCTAssertComponent<F: LogItemFormatComponent>(
        _ component: F,
        item: Log.Item = .dummy(),
        initial: String = "",
        returns expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws where F.Output == String {

        var string = initial
        try component.formatting(item, &string)
        XCTAssertEqual(string, expected, file: file, line: line)
    }
}
