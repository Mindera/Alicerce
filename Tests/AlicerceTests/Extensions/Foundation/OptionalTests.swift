import XCTest

@testable import Alicerce

final class OptionalTests: XCTestCase {

    func testRequire_UsingNonOptionalValue_ShouldUnwrapTheValue() {
        let anOptionalString: String? = "😎"

        let unwrappedValue = anOptionalString.require()

        XCTAssertNotNil(unwrappedValue)
        XCTAssertEqual(anOptionalString, "😎", "🔥: then closure not executed! 😱")
    }
}
