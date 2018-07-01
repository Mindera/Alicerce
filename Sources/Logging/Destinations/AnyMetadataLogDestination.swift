import Foundation

/// A type erased logging destination (or provider) that can set/unset custom logging metadata.
public final class AnyMetadataLogDestination<MetadataKey: Hashable>: MetadataLogDestination {

    /// The destination's minimum severity log level.
    public let minLevel: Log.Level

    /// The destination's identifier.
    public let id: ID

    /// The type erased destination's `write` method, stored as a closure.
    private let _write: (Log.Item, @escaping (Error) -> Void) -> Void

    /// The type erased destination's `setMetadata` method, stored as a closure.
    private let _setMetadata: ([MetadataKey : Any], @escaping (Error) -> Void) -> Void

    /// The type erased destination's `removeMetadata` method, stored as a closure.
    private let _removeMetadata: ([MetadataKey], @escaping (Error) -> Void) -> Void

    /// Creates a type erased instance of a log destination that outputs logs to the console and sets/unsets custom
    /// logging metadata.
    ///
    /// - Parameters:
    ///   - d: The log destination to erase the type from.
    public init<D: MetadataLogDestination>(_ d: D) where D.MetadataKey == MetadataKey {
        minLevel = d.minLevel
        id = d.id
        _write = d.write
        _setMetadata = d.setMetadata
        _removeMetadata = d.removeMetadata
    }

    // MARK: - LogDestination

    /// Writes a log item to the type erased destinations output (e.g. console, file, remove server, etc).
    ///
    /// - Parameters:
    ///   - item: The item to write.
    ///   - onFailure: The closure to be invoked on failure.
    public func write(item: Log.Item, onFailure: @escaping (Error) -> Void) {
        _write(item, onFailure)
    }

    // MARK: - MetadataLogDestination

    /// Sets custom metadata in the type erased destination, to enrich existing log data (e.g. user info, device info,
    /// correlation ids, etc).
    ///
    /// This extra information can be very handy on its own, can and also be used to correlate logs between logging
    /// providers, for instance.
    ///
    /// - Parameters:
    ///   - metadata: The custom metadata to set.
    ///   - onFailure: The closure to be invoked on failure.
    public func setMetadata(_ metadata: [MetadataKey : Any], onFailure: @escaping (Error) -> Void) {
        _setMetadata(metadata, onFailure)
    }

    /// Removes custom metadata from the type erased destination.
    ///
    /// - Parameters:
    ///   - keys: The custom metadata keys to remove.
    ///   - onFailure: The closure to be invoked on failure.
    public func removeMetadata(forKeys keys: [MetadataKey], onFailure: @escaping (Error) -> Void) {
        _removeMetadata(keys, onFailure)
    }
}
