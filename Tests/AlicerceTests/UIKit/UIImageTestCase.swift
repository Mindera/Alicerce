import XCTest
import UIKit

@testable import Alicerce

final class UIImageTestCase: XCTestCase {

    func testOriginal_WhenHasImage_ItShouldReturnTheOriginalImage() {
        let mrMinder = imageFromFile(withName: "mr-minder", type: "png")

        let mrMinderOriginal = mrMinder.original

        XCTAssertEqual(mrMinderOriginal.renderingMode, .alwaysOriginal)
    }

    func testTemplate_WhenHasImage_ItShouldReturnTheTemplateImage() {
        let mrMinder = imageFromFile(withName: "mr-minder", type: "png")

        let mrMinderTemplate = mrMinder.template

        XCTAssertEqual(mrMinderTemplate.renderingMode, .alwaysTemplate)
    }

    func testConvenienceInit_WithImageInBase64_ShouldReturnUIImage() {
        let mrMinder = imageFromFile(withName: "mr-minder", type: "png")

        guard let pngImageData = UIImagePNGRepresentation(mrMinder) else {
            XCTFail("Could not convert mr-minder image to PNG representation")
            return
        }

        let base64String = pngImageData.base64EncodedString()

        guard let image = UIImage(base64Encoded: base64String) else {
            XCTFail("Could not init UIImage from base64 representation")
            return
        }

        XCTAssertEqual(UIImagePNGRepresentation(image), pngImageData)
    }

    func testConvenienceInit_WithPlainTextInBase64_ShouldReturnNilFromInit() {
        let image = UIImage(base64Encoded: "Ym9vbQ==")

        XCTAssertNil(image)
    }

    func testConvenienceInit_WithNoneBase64String_ShouldReturnNilFromInit() {
        let image = UIImage(base64Encoded: "💥")

        XCTAssertNil(image)
    }
}
