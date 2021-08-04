import XCTest
@testable import Alicerce

class NetworkTestCase: XCTestCase {

    // Network.Value

    func testMapValue_WithSuccessMap_ShouldMapValue() {

        let response = URLResponse()
        let value = Network.Value(value: 1337, response: response)

        let mappedValue = value.mapValue { v, r in String(v) }

        XCTAssertEqual(mappedValue.value, "1337")
        XCTAssertIdentical(mappedValue.response, response)
    }

    func testMapValue_WithFailureMap_ShouldThrow() {

        enum MockError: Error { case 🔥 }

        let value = Network.Value(value: 1337, response: URLResponse())

        XCTAssertThrowsError(try value.mapValue { _, _ in throw MockError.🔥 }) {
            guard case MockError.🔥 = $0 else {
                XCTFail("unexpected error: \($0)")
                return
            }
        }
    }
}
