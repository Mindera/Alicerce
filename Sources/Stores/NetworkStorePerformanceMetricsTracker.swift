import Foundation

public protocol NetworkStorePerformanceMetricsTracker: PerformanceMetricsTracker {

    /// The metadata key used for the model type being parsed.
    var modelTypeMetadataKey: Metadata.Key { get }

    /// The metadata key used for the blob size being parsed.
    var payloadSizeMetadataKey: Metadata.Key { get }

    /// Creates a new identifier to be used by a decoding performance metric, for a given `Resource` (and optional
    /// payload).
    ///
    /// - Parameters:
    ///   - resource: The resource to create the metric identifier for.
    ///   - payload: The resource's payload.
    /// - Returns: The new resource decode metric's identifier.
    func makeDecodeIdentifier<R: DecodableResource>(for resource: R, payload: R.External?) -> Identifier

    /// Measures a given `Resource`'s parsing execution time.
    ///
    /// - Parameters:
    ///   - resource: The resource being parsed by `parse`.
    ///   - payload: The resource's received payload, used by `parse`.
    ///   - metadata: The parse metric's metadata dictionary.
    ///   - decode: The resource's decoding closure, to measure the execution time of.
    /// - Returns: The parsing result, if any.
    /// - Throws: The parsing error, if any.
    func measureDecode<R: DecodableResource>(of resource: R,
                                             payload: R.External,
                                             metadata: Metadata?,
                                             decode: () throws -> R.Internal) rethrows -> R.Internal
}

public extension NetworkStorePerformanceMetricsTracker {

    var modelTypeMetadataKey: Metadata.Key { return "model_type" }
    var payloadSizeMetadataKey: Metadata.Key { return "payload_size" }

    func makeDecodeIdentifier<R: DecodableResource>(for resource: R, payload: R.External?) -> Identifier {
        return "Decode \(R.Internal.self)"
    }

    func measureDecode<R: DecodableResource>(of resource: R,
                                             payload: R.External,
                                             metadata: Metadata? = nil,
                                             decode: () throws -> R.Internal) rethrows -> R.Internal {

        return try measure(with: makeDecodeIdentifier(for: resource, payload: payload),
                           metadata: metadata,
                           execute: decode)
    }
}
