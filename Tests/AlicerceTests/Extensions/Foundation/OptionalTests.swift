import XCTest

@testable import Alicerce

final class OptionalTests: XCTestCase {

    func testThen_UsingNonOptionalValue_ShouldUnwrapTheValue() {
        var anOptionalString: String? = "😎"

        if let value = anOptionalString {
            XCTAssertEqual(anOptionalString, value, "🔥: \(value) not unwrapped! 😱")
            anOptionalString = "😇"
        }

        XCTAssertEqual(anOptionalString, "😇", "🔥: then closure not executed! 😱")
    }

    func testThen_UsingOptionalValue_ShoudNotUnwrapTheValue() {
        let nullValue: String? = nil

        if let _ = nullValue {
            XCTFail("💥 nil unwrapped 😱")
        }
    }

    func testRequire_UsingNonOptionalValue_ShouldUnwrapTheValue() {
        let anOptionalString: String? = "😎"

        let unwrappedValue = anOptionalString.require()

        XCTAssertNotNil(unwrappedValue)
        XCTAssertEqual(anOptionalString, "😎", "🔥: then closure not executed! 😱")
    }
}
