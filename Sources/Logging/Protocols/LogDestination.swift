import Foundation

/// A type that represents a logging destination (or provider).
public protocol LogDestination: class {

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

    /// Sets custom metadata in the destination, to enrich existing log data (e.g. user info, device info, correlation
    /// ids, etc).
    ///
    /// This extra information can be very handy on its own, can and also be used to correlate logs between logging
    /// providers, for instance.
    ///
    /// - Parameters:
    ///   - metadata: The custom metadata to set.
    ///   - onFailure: The closure to be invoked on failure.
    func setMetadata(_ metadata: [AnyHashable : Any], onFailure: @escaping (Error) -> Void)

    /// Removes custom metadata from the destination.
    ///
    /// - Parameters:
    ///   - keys: The custom metadata keys to remove.
    ///   - onFailure: The closure to be invoked on failure.
    func removeMetadata(forKeys keys: [AnyHashable], onFailure: @escaping (Error) -> Void)
}

extension LogDestination {

    public var id: ID {
        return "\(type(of: self))"
    }
}
