//
//  GeneratableObjectCache.swift
//  Alicerce
//
//  Created by Filipe Lemos on 02/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

public protocol GeneratableObjectKey: Hashable {
    associatedtype T

    func generate() -> T
}

public final class GeneratableObjectCache<T> {

    private let cache: Atomic<[AnyHashable : T]> = Atomic([:])

    public func value<Generator: GeneratableObjectKey>(_ generator: Generator) -> T where Generator.T == T {

        return cache.modify {
            if let cached = $0[generator] { return cached }

            let generated = generator.generate()
            $0[generator] = generated
            return generated
        }
    }
}
