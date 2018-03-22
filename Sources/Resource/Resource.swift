//
//  Resource.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public typealias ResourceEmptyClosure<U> = () throws -> U
public typealias ResourceMapClosure<U, V> = (U) throws -> V

public protocol Resource {
    associatedtype Remote
    associatedtype Local
    associatedtype Error: Swift.Error

    var parse: ResourceMapClosure<Remote, Local> { get }
    var serialize: ResourceMapClosure<Local, Remote> { get }
    var errorParser: ResourceErrorParseClosure<Remote, Error> { get }
}
