//
//  Resource.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public struct Resource<T> {
    public typealias ParseClosure = (Data) throws -> T

    let path: String
    let method: HTTP.Method
    let headers: HTTP.Headers?
    let query: HTTP.Query?
    let body: Data?
    let parser: ParseClosure

    init(path: String,
         method: HTTP.Method,
         headers: HTTP.Headers? = nil,
         query: HTTP.Query? = nil,
         body: Data? = nil,
         parser: @escaping ParseClosure) {

        self.path = path
        self.method = method
        self.headers = headers
        self.query = query
        self.body = body
        self.parser = parser
    }
}
