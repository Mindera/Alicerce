import XCTest
@testable import Alicerce

class HTTPNetworkResourceTestCase: XCTestCase {

    private typealias Resource = MockHTTPNetworkResource<Void>

    func testMakeRequest_WithDefaultImplementation_ShouldReturnEndpointRequestAndPropagateCancelable() {

        let expectation = self.expectation(description: "makeRequest")

        let resource = Resource()
        let testCancelable = DummyCancelable()

        let cancelable = resource.makeRequest { result in

            defer { expectation.fulfill() }

            switch result {
            case .success(let request):
                XCTAssertEqual(request, resource.endpoint.request)
            case .failure(let error):
                XCTFail("unexpected error: \(error)!")
            }

            return testCancelable
        }

        waitForExpectations(timeout: 1)

        XCTAssert(cancelable === testCancelable)
    }
}

class MockHTTPNetworkResource<T>: HTTPNetworkResource {

    typealias Remote = Data
    typealias Local = T

    typealias Request = URLRequest
    typealias Response = URLResponse
    typealias APIError = MockAPIError

    typealias Endpoint = MockHTTPResourceEndpoint

    enum MockError: Swift.Error { case 😱, 😭 }
    enum MockAPIError: Swift.Error { case 🤬 }

    // Mocks

    var mockParse: ParseClosure = { _ in throw MockError.😱 }
    var mockSerialize: SerializeClosure = { _ in throw MockError.😭 }
    var mockParseAPIError: ParseAPIErrorClosure = { _, _ in return MockAPIError.🤬 }

    var mockEndpoint: Endpoint = MockHTTPResourceEndpoint(baseURL: URL(string: "https://mindera.com")!)

    // Resource

    var parse: ParseClosure { return mockParse }
    var serialize: SerializeClosure { return mockSerialize }

    // NetworkResource

    var parseAPIError: ParseAPIErrorClosure { return mockParseAPIError }
    static var empty: Remote { return Data() }

    // HTTPNetworkResource

    var endpoint: MockHTTPResourceEndpoint { return mockEndpoint }
}
