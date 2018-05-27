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

    func testFormat_ShouldReturnCorrectOutput() {

        do {
            let formattedData = try formatter.format(item: Log.Item.testItem)

            let decodedItem = try JSONDecoder().decode(Log.Item.self, from: formattedData)

            XCTAssertEqual(Log.Item.testItem, decodedItem)
        } catch {
            XCTFail("unexpected error \(error)!")
        }
    }
}
