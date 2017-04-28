//
//  PersistenceStack.swift
//  Alicerce
//
//  Created by Luís Portela on 13/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol PersistenceStack {

    typealias CompletionClosure<R> = (_ inner: () throws -> R) -> Void

    func object(for key: Persistence.Key, completion: @escaping CompletionClosure<Data>)

    func setObject(_ object: Data, for key: Persistence.Key, completion: @escaping CompletionClosure<Void>)

    func removeObject(for key: String, completion: @escaping CompletionClosure<Void>)
}
