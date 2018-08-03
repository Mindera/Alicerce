import XCTest
@testable import Alicerce

class StringTestCase_Localizable: XCTestCase {

    // MARK: - Success

    func testLocalized_WithExistingKeyAndWithoutArguments_ShouldSucceed() {
        let resultString = "this is a test"
        let localizedHelperTest = "test".localized

        XCTAssertEqual(localizedHelperTest, resultString)
    }

    func testLocalizedWithArgs_WithExistingKeyAndValidVariadicArguments_ShouldSucceed() {
        let resultString = "Alicerce 10"
        let localizedHelperTestWithArguments = "test.arguments".localized(with: "Alicerce", 10)

        XCTAssertEqual(localizedHelperTestWithArguments, resultString)
    }

    func testLocalizedWithArgs_WithExistingKeyAndValidArrayArguments_ShouldSucceed() {
        let resultString = "Alicerce 10"
        let localizedHelperTestWithArguments = "test.arguments".localized(with: ["Alicerce", 10])

        XCTAssertEqual(localizedHelperTestWithArguments, resultString)
    }

    func testLocalized_WithInexistingKeyAndWithoutArguments_ShouldReturnKey() {
        let resultString = "inexisting key"
        let localizedHelperTest = "inexisting key".localized

        XCTAssertEqual(localizedHelperTest, resultString)
    }

    func testLocalizedWithArgs_WithInexistingKeyAndValidVariadicArguments_ShouldReturnKey() {
        let resultString = "inexisting key"
        let localizedHelperTestWithArguments = "inexisting key".localized(with: "Alicerce", 10)

        XCTAssertEqual(localizedHelperTestWithArguments, resultString)
    }

    func testLocalizedWithArgs_WithInexistingKeyAndValidArrayArguments_ShouldReturnKey() {
        let resultString = "inexisting key"
        let localizedHelperTestWithArguments = "inexisting key".localized(with: ["Alicerce", 10])

        XCTAssertEqual(localizedHelperTestWithArguments, resultString)
    }

    func testLocalizedWithArgs_WithExistingKeyAndInvalidVariadicArguments_ShouldFail() {
        let resultString = "Alicerce 10"
        let localizedHelperTestWithArguments = "test.arguments".localized(with: "Alicerce")

        XCTAssertNotEqual(localizedHelperTestWithArguments, resultString)
    }

    func testLocalizedWithArgs_WithExistingKeyAndInvalidArrayArguments_ShouldFail() {
        let resultString = "Alicerce 10"
        let localizedHelperTestWithArguments = "test.arguments".localized(with: ["Alicerce"])

        XCTAssertNotEqual(localizedHelperTestWithArguments, resultString)
    }
}
