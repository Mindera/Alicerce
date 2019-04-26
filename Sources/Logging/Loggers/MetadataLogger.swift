import Foundation

/// A type that logs messages with multiple possible severity log levels, and sets/unsets custom logging metadata.
public protocol MetadataLogger: Logger {

    /// A type representing a logger's metadata key.
    associatedtype MetadataKey: Hashable

    /// Sets custom metadata in the logger, to enrich logging data (e.g. user info, device info, correlation ids, etc).
    ///
    /// This extra information can be very handy on its own, can and also be used to correlate logs between logging
    /// providers, for instance.
    ///
    /// - Parameter metadata: The custom metadata to set.
    func setMetadata(_ metadata: [MetadataKey : Any])

    /// Removes custom metadata from the logger, when any previous information became outdated (e.g. user signed out).
    ///
    /// - SeeAlso: `setMetadata(_:)`
    ///
    /// - Parameter keys: The custom metadata keys to remove.
    func removeMetadata(forKeys keys: [MetadataKey])
}

public extension MetadataLogger where Self: MetadataLogDestination {

    func setMetadata(_ metadata: [MetadataKey : Any]) {

        setMetadata(metadata) { error in

            guard self !== Log.internalLogger else { return }

            Log.internalLogger.error("💥 '\(type(of: self))' failed to log metadata: \(metadata) with error: \(error)")
        }
    }

    func removeMetadata(forKeys keys: [MetadataKey]) {

        removeMetadata(forKeys: keys) { error in

            guard self !== Log.internalLogger else { return }

            Log.internalLogger.error("💥 '\(type(of: self))' failed to remove metadata for keys: \(keys) with " +
                                     "error: \(error)")
        }
    }
}
