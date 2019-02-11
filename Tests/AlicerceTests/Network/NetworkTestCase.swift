import XCTest

@testable import Alicerce

final class NetworkTestCase: XCTestCase {

    func testConfiguration_WhenCreateWithFullInit_ItShouldPopulateAllTheValues() {

        let networkConfiguration = Network.Configuration(retryQueue: DispatchQueue(label: "configuration-retry-queue"))

        XCTAssertNil(networkConfiguration.authenticationChallengeHandler)
        XCTAssertTrue(networkConfiguration.requestInterceptors.isEmpty)
    }
    
    func testConfiguration_WhenCreatedWithARequestHandler_ItShouldKeepAReferenceToIt() {
        let dummyRequestInterceptor = DummyRequestInterceptor()
        
        let requestInterceptors = [dummyRequestInterceptor]
        
        let networkConfiguration = Network.Configuration(requestInterceptors: requestInterceptors,
                                                         retryQueue: DispatchQueue(label: "configuration-retry-queue"))
        
        XCTAssertNil(networkConfiguration.authenticationChallengeHandler)
        XCTAssertEqual(networkConfiguration.requestInterceptors.count, 1)
        
        guard let configurationDummyRequestInterceptor
            = networkConfiguration.requestInterceptors.first as? DummyRequestInterceptor
        else { return XCTFail("💥") }
        
        XCTAssertEqual(configurationDummyRequestInterceptor, dummyRequestInterceptor)
    }
}

private final class MockURLSessionConfiguration: URLSessionConfiguration {

    private var headers: [AnyHashable : Any]? = ["👉" : "👈"]

    override var httpAdditionalHeaders: [AnyHashable : Any]? {
        get {
            return headers
        }

        set {
            headers = newValue
        }
    }
}

private final class DummyRequestInterceptor: RequestInterceptor {
    func intercept(request: URLRequest) {}
    
    func intercept(response: URLResponse?, data: Data?, error: Error?, for request: URLRequest) {}
}

extension DummyRequestInterceptor: Equatable {
    static func ==(left: DummyRequestInterceptor, right: DummyRequestInterceptor) -> Bool {
        return true
    }
}
