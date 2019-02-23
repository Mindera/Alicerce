import XCTest
@testable import Alicerce

struct MockMappableModel: Mappable {

    static var mockModel: (Any) throws -> MockMappableModel = {
         throw JSON.Error.unexpectedType(expected: MockMappableModel.self, found: type(of: $0))
    }

    var mockJSON: Any = ""
}

extension MockMappableModel {

    static func model(from object: Any) throws -> MockMappableModel { return try mockModel(object) }

    func json() -> Any { return mockJSON }
}


final class SerializeTestCase: XCTestCase {

    // MARK: - Success tests

    func testJSON_WithSuccessfulSerialization_ShouldReturnData() {

        let model = MappableModel(data: "👍")
        let modelData = try! JSONSerialization.data(withJSONObject: model.json(), options: [])

        do {
            let data = try Serialize.json(object: model)
            XCTAssertEqual(data, modelData)
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }

    func testImageAsPNGData_WithSuccessfulSerialization_ShouldReturnImage() {

        let image = imageFromFile(withName: "mr-minder", type: "png")

        do {
            let data = try Serialize.imageAsPNGData(image)
            XCTAssertEqual(data, image.pngData())
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }

    // MARK: - Error tests

    func testJSON_WithInvalidJSON_ShouldThrowAnInvalidJSONError() {

        var model = MockMappableModel()
        model.mockJSON = "💥"

        do {
            let _ = try Serialize.json(object: model)
            XCTFail("🔥 unexpected success 😱")
        } catch Serialize.Error.invalidJSON(let errorJSON) {
            XCTAssertDumpsEqual(errorJSON, model.json())
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }

    // TODO: JSON failing serialization

    func testImage_WithNonPNGImage_ShouldThrowAnInvalidImageError() {

        let image = UIImage()

        do {
            let _ = try Serialize.imageAsPNGData(image)
            XCTFail("🔥 unexpected success 😱")
        } catch Serialize.Error.invalidImage(let errorImage) {
            XCTAssertEqual(errorImage, image)
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }
}
