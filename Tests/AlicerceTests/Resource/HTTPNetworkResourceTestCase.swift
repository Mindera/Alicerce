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
    typealias Error = MockAPIError
    typealias Request = URLRequest
    typealias Endpoint = MockHTTPResourceEndpoint

    enum MockError: Swift.Error { case 😱, 😭 }
    enum MockAPIError: Swift.Error { case 🤬 }

    // Mocks

    var mockParse: (Remote) throws -> Local = { _ in throw MockError.😱 }
    var mockSerialize: (Local) throws -> Remote = { _ in throw MockError.😭 }
    var mockErrorParser: (Remote) -> Error? = { _ in return MockAPIError.🤬 }

    var mockEndpoint: Endpoint = MockHTTPResourceEndpoint(baseURL: URL(string: "https://mindera.com")!)

    // Resource

    var parse: (Remote) throws -> Local { return mockParse }
    var serialize: (Local) throws -> Remote { return mockSerialize }
    var errorParser: (Remote) -> Error? { return mockErrorParser }

    // NetworkResource

    static var empty: Remote { return Data() }

    // HTTPNetworkResource

    var endpoint: MockHTTPResourceEndpoint { return mockEndpoint }
}
