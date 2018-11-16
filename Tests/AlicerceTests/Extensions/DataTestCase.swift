import XCTest

@testable import Alicerce

final class DataTestCase: XCTestCase {

    func testNSData_WhenItIsAValidData_ItShouldReturnANSData() {
        let stringData = "✅".data(using: .utf8)

        let stringNSData = stringData?.nsData

        let stringFromNSData = String(data: stringNSData! as Data, encoding: .utf8)

        XCTAssertNotNil(stringNSData)
        XCTAssertEqual(stringData!.count, stringNSData!.length)
        XCTAssertEqual(stringFromNSData, "✅")
    }
}

