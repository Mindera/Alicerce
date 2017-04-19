//
//  NetworkResource.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol NetworkResource {
    func toRequest(withBaseURL baseURL: URL) -> URLRequest
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
