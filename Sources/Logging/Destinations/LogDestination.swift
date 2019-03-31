import Foundation

/// A type representing a logging destination (or provider).
public protocol LogDestination: AnyObject {

    /// A type representing a destination's identifier.
    typealias ID = String

    /// The minimum log level of the destination. Any item with a level below this level shouldn't be logged.
    var minLevel: Log.Level { get }

    /// The identifier of the destination. The default is the destination's type name.
    var id: ID { get }

    /// Writes a log item to the destinations output (e.g. console, file, remove server, etc).
    ///
    /// - Parameters:
    ///   - item: The item to write.
    ///   - onFailure: The closure to be invoked on failure.
    func write(item: Log.Item, onFailure: @escaping (Error) -> Void)
}

extension LogDestination {

    public var id: ID {
        return "\(type(of: self))"
    }
}
