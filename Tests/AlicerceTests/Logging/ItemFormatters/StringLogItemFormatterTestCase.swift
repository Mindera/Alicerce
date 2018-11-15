import XCTest
@testable import Alicerce

class StringLogItemFormatterTestCase: XCTestCase {

    typealias Formatter = Log.StringLogItemFormatter
    typealias Format = Log.StringLogItemFormatter.Format

    private var formatter: Formatter!

    override func setUp() {
        super.setUp()

        let format = Format(separator: " ")
            .timestamp("HH:mm:ss.SSS")
            .module()
            .line()
            .joined { $0
                .thread()
                .wrapped(before: "(", after: ")") { $0.queue() }
            }
            .file(withExtension: false)
            .joined { $0
                .file(withExtension: true)
                .text(".")
                .function()
                .text(":")
                .line()
            }
            .text("-")
            .message()

        formatter = Log.StringLogItemFormatter(format: format)
    }

    override func tearDown() {
        formatter = nil

        super.tearDown()
    }

    func testFormat_WithEmptyFormat_ShouldReturnEmptyOutput() {

        formatter = Formatter(format: Format())

        let item = Log.Item.testItem
        let output: String
        do { output = try formatter.format(item: item) } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }

        XCTAssertTrue(output.isEmpty)
    }

    func testFormat_WithValidFormat_ShouldReturnCorrectOutput() {

        let item = Log.Item.testItem
        let output: String
        do { output = try formatter.format(item: item) } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }

        XCTAssertFalse(output.isEmpty)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: item.timestamp)

        let expected: [String] = [
            timestamp,
            item.module!,
            String(item.line),
            "\(item.thread)(\(item.queue))",
            item.file.nsString.deletingPathExtension,
            "\(item.file).\(item.function):\(item.line)",
            "-",
            item.message
        ]

        XCTAssertEqual(output.split(separator: " ").map(String.init), expected)
    }

    func testFormat_WithCustomFormat_ShouldReturnCorrectOutput() {

        var caller: Log.Item?

        let format = Format().custom { item in
            caller = item
            return "lorem"
        }

        formatter = Formatter(format: format)

        let item = Log.Item.testItem
        let output: String
        do { output = try formatter.format(item: item) } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }

        XCTAssertEqual(output, "lorem")
        XCTAssertEqual(caller, item)
    }
}
