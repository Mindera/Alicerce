import XCTest
@testable import Alicerce

class JSONLogItemFormatterTestCase: XCTestCase {

    private var formatter: Log.JSONLogItemFormatter!
    private var encoder: JSONEncoder!

    override func setUp() {
        super.setUp()

        encoder = JSONEncoder()
        formatter = Log.JSONLogItemFormatter(encoder: encoder)
    }

    override func tearDown() {
        encoder = nil
        formatter = nil

        super.tearDown()
    }

    func testFormat_ShouldReturnCorrectOutput() throws {

        let item = Log.Item.dummy()

        let formattedData = try formatter.format(item: item)

        let decodedItem = try JSONDecoder().decode(Log.Item.self, from: formattedData)

        XCTAssertEqual(item, decodedItem)
    }
}
