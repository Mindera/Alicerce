import XCTest
@testable import Alicerce

class AuthenticatedHTTPNetworkResourceTestCase: XCTestCase {

    private typealias Resource = MockAuthenticatedHTTPNetworkResource<Void>

    func testMakeRequest_WithDefaultImplementation_ShouldReturnAuthenticatedEndpointRequestAndPropagateCancelable() {

        let expectation = self.expectation(description: "makeRequest")
        let expectation2 = self.expectation(description: "authenticate")

        let resource = Resource()

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

class MockAuthenticatedHTTPNetworkResource<T>: MockHTTPNetworkResource<T>, AuthenticatedHTTPNetworkResource {

    typealias Authenticator = MockRequestAuthenticator

    // AuthenticatedHTTPNetworkResource

    var authenticator: Authenticator = MockRequestAuthenticator()
}
