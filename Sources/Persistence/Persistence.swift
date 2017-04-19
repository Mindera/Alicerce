//
//  Persistence.swift
//  Alicerce
//
//  Created by Luís Portela on 13/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public enum PersistenceError: Swift.Error {
    case noObjectForKey
    case other(Swift.Error)
}

public protocol Persistence {
    typealias Key = String

    typealias CompletionClosure<R> = (_ inner: () throws -> R) -> Void

    func object(`for` key: Key, completion: @escaping CompletionClosure<Data>)

    func setObject(_ object: Data, for key: Key, completion: @escaping CompletionClosure<Void>)

    func removeObject(for key: String, completion: @escaping CompletionClosure<Void>)
}
