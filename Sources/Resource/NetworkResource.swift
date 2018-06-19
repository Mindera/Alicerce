import Foundation

public protocol NetworkResource: Resource {

    var request: URLRequest { get }

    static var empty: Remote { get }
}

public protocol RelativeNetworkResource: NetworkResource {

    static var baseURL: URL { get }

    var path: String { get }
    var method: HTTP.Method { get }
    var headers: HTTP.Headers? { get }
    var query: HTTP.Query? { get }
    var body: Data? { get }
}

extension RelativeNetworkResource {

    public var request: URLRequest {
        var url = Self.baseURL

        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = build(queryItems: query)
            components.path = components.path
                .appending(path)
                .replacingOccurrences(of: "//", with: "/")

            components.url.then {
                url = $0
            }
        }

        return buildRequest(for: url, method: method, headers: headers, body: body)
    }
}

public protocol StaticNetworkResource: NetworkResource {

    var url: URL { get }
    var method: HTTP.Method { get }
    var headers: HTTP.Headers? { get }
    var query: HTTP.Query? { get }
    var body: Data? { get }
}

extension StaticNetworkResource {

    public var request: URLRequest {

        var newUrl = url

        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            build(queryItems: query).then { components.queryItems = (components.queryItems ?? []) + $0 }

            components.url.then { newUrl = $0 }
        }

        return buildRequest(for: newUrl, method: method, headers: headers, body: body)
    }
}

private func build(queryItems: HTTP.Query?) -> [URLQueryItem]? {
    guard let queryItems = queryItems, queryItems.isEmpty == false else { return nil }

    return queryItems.map { URLQueryItem(name: $0, value: $1) }
}

private func buildRequest(for url: URL, method: HTTP.Method, headers: HTTP.Headers?, body: Data?) -> URLRequest {

    var urlRequest = URLRequest(url: url)

    urlRequest.allHTTPHeaderFields = headers
    urlRequest.httpBody = body
    urlRequest.httpMethod = method.rawValue

    return urlRequest
}
