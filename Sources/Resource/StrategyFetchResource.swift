import Foundation

/// A type representing a resource that can be fetched using multiple strategies.
public protocol StrategyFetchResource {

    /// A type representing the fetch strategy.
    associatedtype Strategy

    /// The resource's fetch strategy.
    var strategy: Strategy { get }
}
