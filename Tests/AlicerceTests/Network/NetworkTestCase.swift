import XCTest

@testable import Alicerce

final class NetworkTestCase: XCTestCase {

    // MARK: Configuration

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

    // MARK: Error

    func testErrorResponse_WhenCaseContainsResponse_ShouldReturnIt() {

        enum DummyError: Error { case 🕳 }

        let testResponse = URLResponse(url: URL(string: "https://mindera.com")!,
                                       mimeType: nil,
                                       expectedContentLength: 1337,
                                       textEncodingName: nil)

        let httpError = Network.Error.http(.unknownError(1337), testResponse)
        let apiError = Network.Error.api(DummyError.🕳, .unknownError(1337), testResponse)
        let noDataError = Network.Error.noData(testResponse)
        let urlError = Network.Error.url(DummyError.🕳, testResponse)
        let badResponseError = Network.Error.badResponse(testResponse)
        let retryError = Network.Error.retry([], 0, .cancelled, testResponse)

        XCTAssertEqual(httpError.response, testResponse)
        XCTAssertEqual(apiError.response, testResponse)
        XCTAssertEqual(noDataError.response, testResponse)
        XCTAssertEqual(urlError.response, testResponse)
        XCTAssertEqual(badResponseError.response, testResponse)
        XCTAssertEqual(retryError.response, testResponse)
    }

    func testErrorResponse_WhenCaseDoesNotContainsResponse_ShouldReturnNil() {

        enum DummyError: Error { case 🕳 }

        let noRequestError = Network.Error.noRequest(DummyError.🕳)
        let urlError = Network.Error.url(DummyError.🕳, nil)
        let badResponseError = Network.Error.badResponse(nil)
        let retryError = Network.Error.retry([], 0, .cancelled, nil)

        XCTAssertNil(noRequestError.response)
        XCTAssertNil(urlError.response)
        XCTAssertNil(badResponseError.response)
        XCTAssertNil(retryError.response)
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

