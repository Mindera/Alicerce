import Foundation

public protocol PersistableResource {
    var persistenceKey: Persistence.Key { get }
}
