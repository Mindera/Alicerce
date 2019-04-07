import XCTest
@testable import Alicerce

class NetworkResourceTestCase: XCTestCase {

    private typealias Resource = MockHTTPNetworkResource<Void>
    private typealias AuthenticatedResource = MockAuthenticatedHTTPNetworkResource<Void>

    // BaseRequestResource `makeRequest`

    func testMakeRequest_WithBaseRequestResourceDefaultImplementation_ShouldReturnEndpointRequestAndPropagateCancelable() {

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

    // AuthenticatedRequestResource & BaseRequestResource `makeRequest`

    func testMakeRequest_WithBaseAndAuthenticatedRequestResourceDefaultImplementation_ShouldReturnAuthenticatedEndpointRequestAndPropagateCancelable() {

        let expectation = self.expectation(description: "makeRequest")
        let expectation2 = self.expectation(description: "authenticate")

        let resource = AuthenticatedResource()

        var authenticatedRequest = resource.endpoint.request

        authenticatedRequest.allHTTPHeaderFields = {
            var headers = $0 ?? [:]
            headers["Authorization"] = "Bearer 🔑"
            return headers
        }(authenticatedRequest.allHTTPHeaderFields)

        resource.authenticator.mockAuthenticate = {

            defer { expectation2.fulfill() }

            XCTAssertEqual($0, resource.endpoint.request)

            return .success(authenticatedRequest)
        }

        let testCancelable = DummyCancelable()

        let cancelable = resource.makeRequest { result in

            defer { expectation.fulfill() }

            switch result {
            case .success(let request):
                XCTAssertEqual(request, authenticatedRequest)
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

    typealias Internal = T
    typealias External = Data

    typealias Request = URLRequest
    typealias Response = URLResponse

    typealias Endpoint = MockHTTPResourceEndpoint

    // Mocks

    var mockEndpoint: Endpoint = MockHTTPResourceEndpoint(baseURL: URL(string: "https://mindera.com")!)

    // HTTPNetworkResource

    var endpoint: MockHTTPResourceEndpoint { return mockEndpoint }
}

class MockAuthenticatedHTTPNetworkResource<T>: MockHTTPNetworkResource<T> & AuthenticatedRequestResource {

    typealias Authenticator = MockRequestAuthenticator

    // AuthenticatedHTTPNetworkResource

    var authenticator: Authenticator = MockRequestAuthenticator()
}
