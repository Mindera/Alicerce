//
//  ImageNetworkResource.swift
//  Alicerce
//
//  Created by Luís Portela on 24/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public struct ImageNetworkResource: NetworkResource {
    public typealias Remote = Data
    public typealias Local = UIImage
    public typealias Error = Parse.Error

    public let url: URL?
    public let path: String?
    public let method: HTTP.Method
    public let headers: HTTP.Headers?
    public let query: HTTP.Query?
    public let body: Data? = nil

    public let parse: ResourceMapClosure<Remote, Local> = Parse.image
    public let serialize: ResourceMapClosure<Local, Remote> = Serialize.imageAsPNGData
    public var errorParser: ResourceErrorParseClosure<Remote, Error> = ErrorParse.image

    public init(url: URL,
                path: String? = nil,
                method: HTTP.Method = .GET,
                headers: HTTP.Headers? = nil,
                query: HTTP.Query? = nil) {

        self.url = url
        self.path = path
        self.method = method
        self.headers = headers
        self.query = query
    }
}
