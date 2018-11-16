// Copyright © 2018 Mindera. All rights reserved.

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
