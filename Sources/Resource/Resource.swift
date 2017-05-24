//
//  Resource.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public typealias ResourceParseClosure<U, V> = (U) throws -> V
public typealias ResourceErrorParseClosure<E: Swift.Error> = (Data) -> E?

public protocol Resource {
    associatedtype Remote
    associatedtype Local
    associatedType E: Swift.Error

    var parser: ResourceParseClosure<Remote, Local> { get }
    var serialize: ResourceParseClosure<Local, Remote> { get }
    var apiErrorParser: ResourceErrorParseClosure<E> { get }
}

//public struct Resource<F, T> {
//
//    let path: String
//    let method: HTTP.Method
//    let headers: HTTP.Headers?
//    let query: HTTP.Query?
//    let body: Data?
//
//    public let parser: ResourceParseClosure<F, T>
//
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
//}
//
//extension Resource: NetworkResource {
//    public func toRequest(withBaseURL baseURL: URL) -> URLRequest {
//        // Make baseURL mutable
//        var url = baseURL
//
//        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
//            components.queryItems = buildQueryItems()
//            components.path = components.path
//                .appending(path)
//                .replacingOccurrences(of: "//", with: "/")
//
//            components.url.then {
//                url = $0
//            }
//        }
//
//        var urlRequest = URLRequest(url: url)
//
//        urlRequest.allHTTPHeaderFields = headers
//        urlRequest.httpBody = body
//        urlRequest.httpMethod = method.rawValue
//
//        return urlRequest
//    }
//
//    private func buildQueryItems() -> [URLQueryItem]? {
//        guard let query = query, query.isEmpty == false else {
//            return nil
//        }
//
//        return query.map { URLQueryItem(name: $0, value: $1) }
//    }
//}
