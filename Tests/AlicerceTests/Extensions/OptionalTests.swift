import XCTest

@testable import Alicerce

final class OptionalTests: XCTestCase {

    func testThen_UsingNonOptionalValue_ShouldUnwrapTheValue() {
        var anOptionalString: String? = "😎"

        anOptionalString.then { value in
            XCTAssertEqual(anOptionalString, value, "🔥: \(value) not unwrapped! 😱")
            anOptionalString = "😇"
        }

        XCTAssertEqual(anOptionalString, "😇", "🔥: then closure not executed! 😱")
    }

    func testThen_UsingOptionalValue_ShoudNotUnwrapTheValue() {
        let nullValue: String? = nil

        nullValue.then { _ in
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
