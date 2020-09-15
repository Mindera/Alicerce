import XCTest
@testable import Alicerce

class ModelDecodingTestCase: XCTestCase {

    struct MockModel: Codable, Equatable {
        let foo: String
    }

    typealias ModelDecoding = Alicerce.ModelDecoding<MockModel, Data, URLResponse>

    func testJSON_WithSuccessDecoding_ShouldReturnModel() {

        let model = MockModel(foo: "bar")
        let data = try! JSONEncoder().encode(model) // swiftlint:disable:this force_try
        let response = URLResponse()

        XCTAssertEqual(try ModelDecoding.json().decode(data, response), model)
    }

    func testJSON_WithFailureDecoding_ShouldThrowDecodingError() {

        let data = Data("{}".utf8)
        let response = URLResponse()

        XCTAssertThrowsError(try ModelDecoding.json().decode(data, response)) {
            guard case DecodingError.keyNotFound(let codingKey, _) = $0 else {
                XCTFail("unexpected error: \($0)")
                return
            }
            
            XCTAssertEqual(codingKey.stringValue, "foo")
        }
    }

}
