//
//  BuildableCache.swift
//  Alicerce
//
//  Created by Filipe Lemos on 02/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

public protocol BuildableKey: Hashable {
    associatedtype T

    func build() -> T
}

public final class BuildableCache<T> {

    private let cache: Atomic<[AnyHashable : T]> = Atomic([:])

    public func object<Key: BuildableKey>(_ key: Key) -> T where Key.T == T {
        return cache.modify {
            if let cached = $0[key] { return cached }

            let built = key.build()
            $0[key] = built
            return built
        }
    }

    public func evict<Key: BuildableKey>(_ key: Key) where Key.T == T {
        cache.modify { $0.removeValue(forKey: key) }
    }

    public func evictAll() {
        cache.modify { $0.removeAll() }
    }
}
