import Foundation

/// A type representing a resource that can be fetched using multiple strategies.
public protocol StrategyFetchResource {

    /// A type representing the fetch strategy.
    associatedtype Strategy

    /// The resource's fetch strategy.
    var strategy: Strategy { get }
}

/// A type representing the fetch strategy used on a `NetworkStore`.
public enum NetworkStoreFetchStrategy {

    /// The fetch should be made to the network first, and on failure to the persistence.
    case networkThenPersistence

    /// The fetch should be made to the persistence first, and on failure to the network.
    case persistenceThenNetwork
}

/// A type representing a resource that can be fetched on a `NetworkStore` using a `NetworkStoreFetchStrategy`.
public protocol NetworkStoreStrategyFetchResource: StrategyFetchResource where Strategy == NetworkStoreFetchStrategy {}
