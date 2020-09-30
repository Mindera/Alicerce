import Foundation

/// A type representing an HTTP resource's endpoint, to generate its request.
///
/// Especially useful when conformed to by an enum, allowing a type safe modelling of an API's endpoints.
public protocol HTTPResourceEndpoint {

    /// The HTTP method.
    var method: HTTP.Method { get }

    /// The base URL.
    var baseURL: URL { get }

    /// The URL's path subcomponent.
    var path: String? { get }

    /// The URL's query string items.
    var queryItems: [URLQueryItem]? { get }

    /// The HTTP header fields.
    var headers: HTTP.Headers? { get }

    // Makes the HTTP message body data.
    func makeBody() throws -> Data?

    // Makes the URL request.
    func makeRequest() throws -> URLRequest
}

public extension HTTPResourceEndpoint {

    var path: String? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var headers: HTTP.Headers? { nil }

    func makeBody() throws -> Data? { nil }

    func makeRequest() throws -> URLRequest {

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            assertionFailure("😱 Failed to create components from URL: \(baseURL) on \(type(of: self))!")
            return URLRequest(url: baseURL)
        }

        if let queryItems = queryItems {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }

        if let path = path {
            components.path = components.path.appending(path).replacingOccurrences(of: "//", with: "/")
        }

        guard let url = components.url else {
            assertionFailure("😱 Failed to extract URL from components: \(components) on \(type(of: self))!")
            return URLRequest(url: baseURL)
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.httpBody = try makeBody()

        return urlRequest
    }
}
