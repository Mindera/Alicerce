//
//  NetworkStore.swift
//  Alicerce
//
//  Created by Luís Portela on 19/01/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

public enum NetworkStoreValue<T> {
    case network(T)
    case persistence(T)

    public var value: T {
        switch self {
        case .network(let value): return value
        case .persistence(let value): return value
        }
    }
}

public typealias NetworkStoreCompletionClosure<T, E: Error> = (_ value: NetworkStoreValue<T>?, _ error: E?) -> Void

public protocol NetworkStore {

    associatedtype Remote
    associatedtype E: Error

    @discardableResult
    func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>) -> Cancelable
    where R: NetworkResource & PersistableResource & StrategyFetchResource, R.Remote == Remote
}
