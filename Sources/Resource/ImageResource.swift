//
//  ImageResource.swift
//  Pods
//
//  Created by Luís Portela on 24/05/2017.
//
//

import Foundation

struct ImageNetworkResource: NetworkResource {
    typealias F = Data
    typealias T = UIImage

    let url: URL?
    let path: String
    let method: HTTP.Method
    let headers: HTTP.Headers?
    var query: HTTP.Query?
    var body: Data? = nil

    let parser: ResourceParseClosure<F, T> = Parse.image

    public init(url: URL? = nil,
                path: String,
                method: HTTP.Method = .GET,
                headers: HTTP.Headers? = nil,
                query: HTTP.Query? = nil,
                body: Data? = nil,
                parser: @escaping ResourceParseClosure<F, T>) {

        self.url = url
        self.path = path
        self.method = method
        self.headers = headers
        self.query = query
        self.body = body
    }
}
