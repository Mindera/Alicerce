import XCTest
import Alicerce

class HTTPResourceEndpointTestCase: XCTestCase {

    // basic resource (i.e. using extension's default `nil property values for path, query items, headers and body)

    func testRequest_WithResourceUsingExtensionDefaultProperties_ShouldReturnRequestWithJustMethodAndBaseURL() {

        let method = HTTP.Method.GET
        let url = URL(string: "https://mindera.com/somepath")!

        let resource = MockBasicHTTPResourceEndpoint(method: method, baseURL: url)

        let builtRequest = resource.request

        XCTAssertEqual(builtRequest.url, url, "💥 the URLs should be the same")
        XCTAssertEqual(builtRequest.httpMethod, method.rawValue)
        XCTAssertEqual(builtRequest.allHTTPHeaderFields, [:])
        XCTAssertNil(builtRequest.httpBody)
    }

    // directly assignable properties (method, headers, body)

    func testRequest_WithDirectlyAssignableProperties_ShouldReturnRequestWithCorrectValues() {

        let method = HTTP.Method.HEAD
        let url = URL(string: "https://mindera.com")!
        let queryItems = [URLQueryItem(name: "item1", value: "one"),
                          URLQueryItem(name: "item2", value: "two")]
        let headers = ["header1" : "value1",
                       "header2" : "value2"]

        let body = "🚀".data(using: .utf8)!

        let resource = MockHTTPResourceEndpoint(method: method,
                                                baseURL: url,
                                                path: "/somepath/another",
                                                queryItems: queryItems,
                                                headers: headers,
                                                body: body)

        let builtRequest = resource.request

        let expectedURL = URL(string: "https://mindera.com/somepath/another?item1=one&item2=two")!

        XCTAssertEqual(builtRequest.url, expectedURL, "💥 the URLs should be the same")
        XCTAssertEqual(builtRequest.httpMethod, method.rawValue)
        XCTAssertEqual(builtRequest.allHTTPHeaderFields, headers)
        XCTAssertEqual(builtRequest.httpBody, body)
    }

    // no custom path

    func testRequest_WithoutPathOnBaseURLAndNoCustomPath_ShouldReturnTheSameURL() {

        let url = URL(string: "https://mindera.com")!
        let resource = MockHTTPResourceEndpoint(baseURL: url)

        let builtRequest = resource.request

        XCTAssertEqual(builtRequest.url, url, "💥 the URLs should be the same")
    }

    func testRequest_WithPathOnBaseURLAndNoCustomPath_ShouldReturnTheSameURL() {

        let url = URL(string: "https://mindera.com/somepath/")!

        let resource = MockHTTPResourceEndpoint(baseURL: url)

        let builtRequest = resource.request

        XCTAssertEqual(builtRequest.url, url, "💥 the URLs should be the same")
    }

    // custom path

    func testRequest_WithoutPathOnBaseURLAndCustomPath_ShouldReturnTheURLWithTheCustomPath() {

        let url = URL(string: "https://mindera.com")!
        let path = "/somepath"

        let resource = MockHTTPResourceEndpoint(baseURL: url, path: path)

        let builtRequest = resource.request

        let expectedURL = URL(string: "https://mindera.com/somepath")!

        XCTAssertEqual(builtRequest.url, expectedURL, "💥 the URLs should be the same")
    }

    func testRequest_WithPathOnBaseURLAndCustomPath_ShouldReturnTheURLWithConatenatedPaths() {

        let url = URL(string: "https://mindera.com/somepath/")!
        let path = "/another/path"

        let resource = MockHTTPResourceEndpoint(baseURL: url, path: path)

        let builtRequest = resource.request

        let expectedURL = URL(string: "https://mindera.com/somepath/another/path")!

        XCTAssertEqual(builtRequest.url, expectedURL, "💥 the URLs should be the same")
    }

    // no custom queryItems

    func testRequest_WithoutQueryItemsOnBaseURLAndNoCustomQueryItems_ShouldReturnTheSameURL() {

        let url = URL(string: "https://mindera.com/somepath/")!
        let resource = MockHTTPResourceEndpoint(baseURL: url)

        let builtRequest = resource.request

        XCTAssertEqual(builtRequest.url, url, "💥 the URLs should be the same")
    }

    func testRequest_WithQueryItemsOnBaseURLAndNoCustomQueryItems_ShouldReturnTheSameURL() {

        let url = URL(string: "https://mindera.com/somepath/?item1=one&item2=two")!

        let resource = MockHTTPResourceEndpoint(baseURL: url)

        let builtRequest = resource.request

        XCTAssertEqual(builtRequest.url, url, "💥 the URLs should be the same")
    }

    // custom queryItems

    func testRequest_WithoutQueryItemsOnBaseURLAndCustomQueryItems_ShouldReturnTheURLWithCustomQueryItems() {

        let url = URL(string: "https://mindera.com/somepath/")!
        let queryItems = [URLQueryItem(name: "item1", value: "one"),
                          URLQueryItem(name: "item2", value: "two")]

        let resource = MockHTTPResourceEndpoint(baseURL: url, queryItems: queryItems)

        let builtRequest = resource.request

        let expectedURL = URL(string: "https://mindera.com/somepath/?item1=one&item2=two")!

        XCTAssertEqual(builtRequest.url, expectedURL, "💥 the URLs should be the same")
    }

    func testRequest_WithQueryItemsOnBaseURLAndCustomQueryItems_ShouldReturnTheURLWithAllQueryItems() {

        let url = URL(string: "https://mindera.com/somepath/?item1=one&item2=two")!
        let queryItems = [URLQueryItem(name: "item3", value: "three"),
                          URLQueryItem(name: "item4", value: "four")]

        let resource = MockHTTPResourceEndpoint(baseURL: url, queryItems: queryItems)

        let builtRequest = resource.request

        let expectedURL = URL(string: "https://mindera.com/somepath/?item1=one&item2=two&item3=three&item4=four")!

        XCTAssertEqual(builtRequest.url, expectedURL, "💥 the URLs should be the same")
    }
}
