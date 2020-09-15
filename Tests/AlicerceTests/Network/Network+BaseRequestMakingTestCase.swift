import XCTest
@testable import Alicerce

class Network_BaseRequestMakingTestCase: XCTestCase {

    func testEndpoint_WithSuccessEndpointMakeRequest_ShouldReturnRequest() {

        let request = URLRequest(url: URL(string: "https://mindera.com")!)

        var endpoint = MockHTTPResourceEndpoint()
        endpoint.mockMakeRequest = { request }

        let baseRequestMaking = Network.BaseRequestMaking.endpoint(endpoint)

        let mockCancelable = MockCancelable()
        let cancelable = baseRequestMaking.make { result in
            switch result {
            case .success(request):
                break
            default:
                XCTFail("unexpected make result: \(result)")
            }

            return mockCancelable
        }

        XCTAssert(cancelable === mockCancelable)
    }

    func testEndpoint_WithFailureEndpointMakeRequest_ShouldReturnFailure() {

        enum MockError: Error { case 🍌 }

        var endpoint = MockHTTPResourceEndpoint()
        endpoint.mockMakeRequest = { throw MockError.🍌 }

        let baseRequestMaking = Network.BaseRequestMaking.endpoint(endpoint)

        let mockCancelable = MockCancelable()
        let cancelable = baseRequestMaking.make { result in
            switch result {
            case .failure(MockError.🍌):
                break
            default:
                XCTFail("unexpected make result: \(result)")
            }

            return mockCancelable
        }

        XCTAssert(cancelable === mockCancelable)
    }
}
