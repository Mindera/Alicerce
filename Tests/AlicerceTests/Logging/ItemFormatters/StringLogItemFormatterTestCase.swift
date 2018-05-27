import XCTest
@testable import Alicerce

class StringLogItemFormatterTestCase: XCTestCase {

    private var formatter: Log.StringLogItemFormatter!

    private let dateFormat = "HH:mm:ss.SSS"

    private var dateFormatter: DateFormatter!
    private var levelFormatter: MockLogLevelFormatter!

    override func setUp() {
        super.setUp()

        let formatString = "$D\(dateFormat)$d $O $C$L$c $T($Q) $N $n.$F:$l - $M $z🤔 $#"
        levelFormatter = MockLogLevelFormatter()
        dateFormatter = DateFormatter()

        formatter = Log.StringLogItemFormatter(formatString: formatString,
                                               levelFormatter: levelFormatter,
                                               dateFormatter: dateFormatter)
    }

    override func tearDown() {
        levelFormatter = nil
        dateFormatter = nil
        formatter = nil

        super.tearDown()
    }

    func testFormat_WithValidFormatString_ShouldReturnCorrectOutput() {

        let item = Log.Item.testItem

        levelFormatter.mockColorString = {
            XCTAssertEqual($0, item.level)
            return "🎨"
        }

        levelFormatter.mockLabelString = {
            XCTAssertEqual($0, item.level)
            return "🏷"
        }

        do {
            let formattedString = try formatter.format(item: item)

            dateFormatter.dateFormat = dateFormat
            let timestamp = dateFormatter.string(from: item.timestamp)
            let colorLabel = "$cE🎨🏷$cR"
            let threadAndQueue = "\(item.thread)(\(item.queue))"
            let filename = item.file.nsString.deletingPathExtension
            let fileFunctionAndLine = "\(item.file).\(item.function):\(item.line)"

            let expectedString = "\(timestamp) \(item.module!) \(colorLabel) \(threadAndQueue) \(filename) " +
                                 "\(fileFunctionAndLine) - \(item.message) 🤔 #"

            XCTAssertEqual(formattedString, expectedString)
        } catch {
            XCTFail("unexpected error \(error)!")
        }
    }
}
