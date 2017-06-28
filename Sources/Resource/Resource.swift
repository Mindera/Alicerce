//
//  Resource.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public struct Resource<T, E: Error> {

    let path: String
    let method: HTTP.Method
    let headers: HTTP.Headers?
    let query: HTTP.Query?
    let body: Data?

    public let parser: ResourceParseClosure<T>
    public let apiErrorParser: ResourceErrorParseClosure<E>

    public init(path: String,
                method: HTTP.Method,
                headers: HTTP.Headers? = nil,
                query: HTTP.Query? = nil,
                body: Data? = nil,
                parser: @escaping ResourceParseClosure<T>,
                apiErrorParser: @escaping ResourceErrorParseClosure<E>) {

        self.path = path
        self.method = method
        self.headers = headers
        self.query = query
        self.body = body
        self.parser = parser
        self.apiErrorParser = apiErrorParser
    }
}

extension Resource: NetworkResource {
    public func toRequest(withBaseURL baseURL: URL) -> URLRequest {
        // Make baseURL mutable
        var url = baseURL

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
