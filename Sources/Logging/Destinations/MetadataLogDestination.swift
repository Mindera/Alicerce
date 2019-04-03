import Foundation

/// A type representing a logging destination (or provider) that can set/unset custom logging metadata.
public protocol MetadataLogDestination: LogDestination {

    /// A type representing a log destination's metadata key.
    associatedtype MetadataKey: Hashable

    /// Sets custom metadata in the destination, to enrich existing log data (e.g. user info, device info, correlation
    /// ids, etc).
    ///
    /// This extra information can be very handy on its own, can and also be used to correlate logs between logging
    /// providers, for instance.
    ///
    /// - Parameters:
    ///   - metadata: The custom metadata to set.
    ///   - onFailure: The closure to be invoked on failure.
    func setMetadata(_ metadata: [MetadataKey : Any], onFailure: @escaping (Error) -> Void)

    /// Removes custom metadata from the destination.
    ///
    /// - Parameters:
    ///   - keys: The custom metadata keys to remove.
    ///   - onFailure: The closure to be invoked on failure.
    func removeMetadata(forKeys keys: [MetadataKey], onFailure: @escaping (Error) -> Void)
}
