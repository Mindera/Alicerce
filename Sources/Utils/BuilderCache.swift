import Foundation

public protocol Builder {
    associatedtype T

    func build() -> T
}

public typealias BuilderKey = Builder & Hashable

public final class BuilderCache<T> {

    private let cache: Atomic<[AnyHashable: T]> = Atomic([:])

    public init() {}

    public func object<Key: BuilderKey>(_ key: Key) -> T where Key.T == T {
        return cache.modify {
            if let cached = $0[key] { return cached }

            let built = key.build()
            $0[key] = built
            return built
        }
    }

    public func evict<Key: BuilderKey>(_ key: Key) where Key.T == T {
        cache.modify { $0.removeValue(forKey: key) }
    }

    public func evictAll() {
        cache.modify { $0.removeAll() }
    }
}
