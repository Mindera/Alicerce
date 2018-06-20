import Foundation

public enum StoreFetchStrategy {

    /**
     This mode should make sure that the store tries to fetch data
     from the network stack first, and if it fails checks the
     persistence stack for the data.
     */
    case networkThenPersistence

    /**
     This mode should make sure that the store tries to retrieve
     the data from the persistence stack first, and if it fails
     tries to fetch the data from the network stack.
     */
    case persistenceThenNetwork
}

public protocol StrategyFetchResource {

    var strategy: StoreFetchStrategy { get }
}
