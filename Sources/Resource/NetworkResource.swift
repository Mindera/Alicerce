//
//  NetworkResource.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol NetworkResource: Resource {

    var url: URL? { get }
    var path: String { get }
    var method: HTTP.Method { get }
    var headers: HTTP.Headers? { get }
    var query: HTTP.Query? { get }
    var body: Data? { get }

//    public init(path: String,
//                method: HTTP.Method,
//                headers: HTTP.Headers? = nil,
//                query: HTTP.Query? = nil,
//                body: Data? = nil,
//                parser: @escaping ResourceParseClosure<F, T>) {
//
//        self.path = path
//        self.method = method
//        self.headers = headers
//        self.query = query
//        self.body = body
//        self.parser = parser
//    }
}

extension NetworkResource {
    public func toRequest(withBaseURL baseURL: URL?) -> URLRequest {
        var url = (self.url ?? baseURL).require(hint: "💥 Failed to get a baseURL")

        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = buildQueryItems()
            components.path = components.path
                .appending(path)
                .replacingOccurrences(of: "//", with: "/")

            components.url.then {
                url = $0
            }
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.allHTTPHeaderFields = headers
        urlRequest.httpBody = body
        urlRequest.httpMethod = method.rawValue

        return urlRequest
    }

    private func buildQueryItems() -> [URLQueryItem]? {
        guard let query = query, query.isEmpty == false else {
            return nil
        }

        return query.map { URLQueryItem(name: $0, value: $1) }
    }
}
