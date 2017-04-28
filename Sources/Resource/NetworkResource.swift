//
//  NetworkResource.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public typealias ResourceParseClosure<T> = (Data) throws -> T

public protocol NetworkResource {
    associatedtype T

    var parser: ResourceParseClosure<T> { get }

    func toRequest(withBaseURL baseURL: URL) -> URLRequest
}
