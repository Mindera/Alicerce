import Foundation

public enum StackOrchestrator {

    public enum FetchValue<T, Response> {
        case network(T, Response)
        case persistence(T)

        public var value: T {
            switch self {
            case .network(let value, _): return value
            case .persistence(let value): return value
            }
        }
    }

    public struct FetchResource<NetworkResource, PersistenceKey> {
        var strategy: FetchStrategy
        var networkResource: NetworkResource
        var persistenceKey: PersistenceKey

        public init(strategy: FetchStrategy, networkResource: NetworkResource, persistenceKey: PersistenceKey) {
            self.strategy = strategy
            self.networkResource = networkResource
            self.persistenceKey = persistenceKey
        }
    }

    public enum FetchStrategy {
        case networkThenPersistence
        case persistenceThenNetwork
    }

    public enum FetchError: Error {
        case network(Error)
        case persistence(Error)
        case cancelled(Error?)
        case multiple([Error])
    }
}
