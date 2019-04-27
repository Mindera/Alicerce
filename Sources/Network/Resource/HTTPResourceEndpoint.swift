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

    // The HTTP message body data.
    var body: Data? { get }
}

public extension HTTPResourceEndpoint {

    var path: String? { return nil }
    var queryItems: [URLQueryItem]? { return nil }
    var headers: HTTP.Headers? { return nil }
    var body: Data? { return nil }
}

public extension HTTPResourceEndpoint {

    /// The endpoint's generated request.
    var request: URLRequest {

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
        urlRequest.httpBody = body

        return urlRequest
    }
}
