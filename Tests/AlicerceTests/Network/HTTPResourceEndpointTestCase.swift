import XCTest
import Alicerce

class HTTPResourceEndpointTestCase: XCTestCase {

    struct MockBasicHTTPResourceEndpoint: HTTPResourceEndpoint {

        var method: HTTP.Method = .GET
        var baseURL: URL = URL(string: "https://mindera.com")!
        var path: String? = nil
        var queryItems: [URLQueryItem]? = nil
        var headers: HTTP.Headers? = nil

        var mockBody: Result<Data?, Error> = .success(nil)

        func makeBody() throws -> Data? { try mockBody.get() }
    }

    private var resource: MockBasicHTTPResourceEndpoint!

    override func setUpWithError() throws {

        resource = MockBasicHTTPResourceEndpoint()
    }

    override func tearDownWithError() throws {

        resource = nil
    }

    // basic resource (i.e. using extension's default `nil property values for path, query items, headers and body)

    func testMakeRequest_WithResourceUsingExtensionDefaultProperties_ShouldReturnRequestWithJustMethodAndBaseURL() throws {

        resource.method = .GET
        resource.baseURL = URL(string: "https://mindera.com/somepath")!

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
        XCTAssertEqual(builtRequest.httpMethod, resource.method.rawValue)
        XCTAssertEqual(builtRequest.allHTTPHeaderFields, [:])
        XCTAssertNil(builtRequest.httpBody)
    }

    // directly assignable properties (method, headers, body)

    func testMakeRequest_WithDirectlyAssignableProperties_ShouldReturnRequestWithCorrectValues() throws {

        resource.method = .HEAD
        resource.baseURL = URL(string: "https://mindera.com")!
        resource.path = "/somepath/another"
        resource.queryItems = [
            URLQueryItem(name: "item1", value: "one"),
            URLQueryItem(name: "item2", value: "two")
        ]
        resource.headers = [
            "header1" : "value1",
            "header2" : "value2"
        ]
        let mockBody = Data("🚀".utf8)
        resource.mockBody = .success(mockBody)

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, URL(string: "https://mindera.com/somepath/another?item1=one&item2=two")!)
        XCTAssertEqual(builtRequest.httpMethod, resource.method.rawValue)
        XCTAssertEqual(builtRequest.allHTTPHeaderFields, resource.headers)
        XCTAssertEqual(builtRequest.httpBody, mockBody)
    }

    // no custom path

    func testMakeRequest_WithoutPathOnBaseURLAndNoCustomPath_ShouldReturnTheSameURL() throws {

        resource.baseURL = URL(string: "https://mindera.com")!
        resource.path = nil

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
    }

    func testMakeRequest_WithPathOnBaseURLAndNoCustomPath_ShouldReturnTheSameURL() throws {

        resource.baseURL = URL(string: "https://mindera.com/somepath/")!
        resource.path = nil

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
    }

    // custom path

    func testMakeRequest_WithoutPathOnBaseURLAndCustomPath_ShouldReturnTheURLWithTheCustomPath() throws {

        resource.baseURL = URL(string: "https://mindera.com")!
        resource.path = "/somepath"

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, URL(string: "https://mindera.com/somepath")!)
    }

    func testMakeRequest_WithPathOnBaseURLAndCustomPath_ShouldReturnTheURLWithConatenatedPaths() throws {

        resource.baseURL = URL(string: "https://mindera.com/somepath/")!
        resource.path = "/another/path"

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, URL(string: "https://mindera.com/somepath/another/path")!)
    }

    // no custom queryItems

    func testMakeRequest_WithoutQueryItemsOnBaseURLAndNoCustomQueryItems_ShouldReturnTheSameURL() throws {

        resource.baseURL = URL(string: "https://mindera.com/somepath/")!
        resource.queryItems = nil

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
    }

    func testMakeRequest_WithQueryItemsOnBaseURLAndNoCustomQueryItems_ShouldReturnTheSameURL() throws {

        resource.baseURL = URL(string: "https://mindera.com/somepath/?item1=one&item2=two")!
        resource.queryItems = nil

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
    }

    // custom queryItems

    func testMakeRequest_WithoutQueryItemsOnBaseURLAndCustomQueryItems_ShouldReturnTheURLWithCustomQueryItems() throws {

        resource.baseURL = URL(string: "https://mindera.com/somepath/")!
        resource.queryItems = [
            URLQueryItem(name: "item1", value: "one"),
            URLQueryItem(name: "item2", value: "two")
        ]

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, URL(string: "https://mindera.com/somepath/?item1=one&item2=two")!)
    }

    func testMakeRequest_WithQueryItemsOnBaseURLAndCustomQueryItems_ShouldReturnTheURLWithAllQueryItems() throws {

        resource.baseURL = URL(string: "https://mindera.com/somepath/?item1=one&item2=two")!
        resource.queryItems = [
            URLQueryItem(name: "item3", value: "three"),
            URLQueryItem(name: "item4", value: "four")
        ]

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(
            builtRequest.url,
            URL(string: "https://mindera.com/somepath/?item1=one&item2=two&item3=three&item4=four")!
        )
    }

    // headers

    func testMakeRequest_WithoutHeaders_ShouldReturnTheRequestWithoutHeaders() throws {

        resource.baseURL = URL(string: "https://mindera.com")!
        resource.headers = nil

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
        XCTAssertEqual(builtRequest.allHTTPHeaderFields, [:])
    }

    func testMakeRequest_WithCustomHeaders_ShouldReturnTheRequestWithCustomHeaders() throws {

        resource.baseURL = URL(string: "https://mindera.com/")!
        resource.headers = [
            "header1" : "value1",
            "header2" : "value2"
        ]

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
        XCTAssertEqual(builtRequest.allHTTPHeaderFields, resource.headers)
    }

    // makeBody

    func testMakeRequest_WithDefaulMakeBody_ShouldReturnTheRequestWithNilBody() throws {

        struct MockDefaultBodyHTTPResourceEndpoint: HTTPResourceEndpoint {

            var method: HTTP.Method = .GET
            var baseURL: URL = URL(string: "https://mindera.com")!
        }

        let resource = MockDefaultBodyHTTPResourceEndpoint()

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
        XCTAssertNil(builtRequest.httpBody)
    }

    func testMakeRequest_WithSuccessNilMakeBody_ShouldReturnTheRequestWithNilBody() throws {

        resource.baseURL = URL(string: "https://mindera.com")!
        resource.mockBody = .success(nil)

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
        XCTAssertNil(builtRequest.httpBody)
    }

    func testMakeRequest_WithSuccessNonNilMakeBody_ShouldReturnTheRequestWithCorrectBody() throws {

        resource.baseURL = URL(string: "https://mindera.com")!
        let mockBody = Data("📦".utf8)
        resource.mockBody = .success(mockBody)

        let builtRequest = try resource.makeRequest()

        XCTAssertEqual(builtRequest.url, resource.baseURL)
        XCTAssertEqual(builtRequest.httpBody, mockBody)
    }

    func testMakeRequest_WithThrowingMakeBody_ShouldThrow() {

        enum MockError: Error { case 💥 }

        resource.baseURL = URL(string: "https://mindera.com/")!
        resource.mockBody = .failure(MockError.💥)

        XCTAssertThrowsError(try resource.makeRequest()) { error in
            guard case MockError.💥 = error else {
                XCTFail("unexpected error \(error)")
                return
            }
        }
    }
}
