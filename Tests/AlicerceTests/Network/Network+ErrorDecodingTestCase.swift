import XCTest
@testable import Alicerce

class Network_ErrorDecodingTestCase: XCTestCase {

    struct MockError: Error, Codable, Equatable {
        let foo: String
    }

    typealias ErrorDecoding = Network.ErrorDecoding<Data, URLResponse>

    func testJSON_WithNilData_ShouldReturnNil() {

        let data: Data? = nil
        let response = URLResponse()

        XCTAssertNil(ErrorDecoding.json(MockError.self).decode(data, response))
    }

    func testJSON_WithNonNilDataAndSuccessDecoding_ShouldReturnError() {

        let error = MockError(foo: "bar")
        let data = try! JSONEncoder().encode(error) // swiftlint:disable:this force_try
        let response = URLResponse()

        XCTAssertDumpsEqual(ErrorDecoding.json(MockError.self).decode(data, response), error)
    }

    func testJSON_WithNonNilDataAndFailureDecoding_ShouldReturnNil() {

        let data = Data("{}".utf8)
        let response = URLResponse()

        XCTAssertNil(ErrorDecoding.json(MockError.self).decode(data, response))
    }
}
