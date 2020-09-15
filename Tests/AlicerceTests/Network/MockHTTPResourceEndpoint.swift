import Foundation
import Alicerce

struct MockHTTPResourceEndpoint: HTTPResourceEndpoint {

    var mockMethod: HTTP.Method = .GET
    var mockBaseURL: URL = URL(string: "https://www.mindera.com")!
    var mockPath: String? = nil
    var mockQueryItems: [URLQueryItem]? = nil
    var mockHeaders: HTTP.Headers? = nil

    var mockBody: () throws -> Data = { Data() }
    var mockMakeRequest: () throws -> URLRequest = { URLRequest(url: URL(string: "https://www.mindera.com")!) }

    // HTTPResourceEndpoint

    var method: HTTP.Method { mockMethod }
    var baseURL: URL { mockBaseURL }

    var path: String? { mockPath }
    var queryItems: [URLQueryItem]? { mockQueryItems }
    var headers: HTTP.Headers? { mockHeaders }

    func makeBody() throws -> Data? { try mockBody() }
    func makeRequest() throws -> URLRequest { try mockMakeRequest() }
}
