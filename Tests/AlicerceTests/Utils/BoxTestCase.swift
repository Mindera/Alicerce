import XCTest
@testable import Alicerce

class BoxTestCase: XCTestCase {

    func testBox_ShouldWrapValue() {

        let value = 1337
        let box = Box<Int>(value)

        XCTAssertEqual(value, box.value)
    }

    func testVarBox_ShouldWrapValueAndAllowModifying() {

        let value = 1337
        let varBox = VarBox<Int>(value)

        XCTAssertEqual(value, varBox.value)

        let newValue = 7331
        varBox.value = newValue

        XCTAssertEqual(newValue, varBox.value)
    }
}
