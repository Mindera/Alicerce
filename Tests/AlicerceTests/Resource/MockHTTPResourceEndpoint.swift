import Foundation
import Alicerce

struct MockHTTPResourceEndpoint: HTTPResourceEndpoint {

    var method: HTTP.Method
    var baseURL: URL

    var path: String? = nil
    var queryItems: [URLQueryItem]? = nil
    var headers: HTTP.Headers? = nil
    var body: Data? = nil

    init(method: HTTP.Method = .GET,
         baseURL: URL,
         path: String? = nil,
         queryItems: [URLQueryItem]? = nil,
         headers: HTTP.Headers? = nil,
         body: Data? = nil) {

        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}

struct MockBasicHTTPResourceEndpoint: HTTPResourceEndpoint {

    var method: HTTP.Method
    var baseURL: URL
}
