import Foundation

public protocol NetworkStorePerformanceMetricsTracker: PerformanceMetricsTracker {

    /// The metadata key used for the model type being parsed.
    var modelTypeMetadataKey: Metadata.Key { get }

    /// The metadata key used for the blob size being parsed.
    var payloadSizeMetadataKey: Metadata.Key { get }

    /// Creates a new identifier to be used by a parsing performance metric, for a given `Resource` (and optional
    /// payload).
    ///
    /// - Parameters:
    ///   - resource: The resource to create the metric identifier for.
    ///   - payload: The resource's payload.
    /// - Returns: The new resource parse metric's identifier.
    func makeParseIdentifier<R: Resource>(for resource: R, payload: R.Remote?) -> Identifier

    /// Measures a given `Resource`'s parsing execution time.
    ///
    /// - Parameters:
    ///   - resource: The resource being parsed by `parse`.
    ///   - payload: The resource's received payload, used by `parse`.
    ///   - metadata: The parse metric's metadata dictionary.
    ///   - parse: The resource's parsing closure, to measure the execution time of.
    /// - Returns: The parsing result, if any.
    /// - Throws: The parsing error, if any.
    func measureParse<R: Resource>(of resource: R,
                                   payload: R.Remote,
                                   metadata: Metadata?,
                                   parse: () throws -> R.Local) rethrows -> R.Local
}

public extension NetworkStorePerformanceMetricsTracker {

    var modelTypeMetadataKey: Metadata.Key { return "model_type" }
    var payloadSizeMetadataKey: Metadata.Key { return "payload_size" }

    func makeParseIdentifier<R: Resource>(for resource: R, payload: R.Remote?) -> Identifier {
        return "Parse \(R.Local.self)"
    }

    func measureParse<R: Resource>(of resource: R,
                                   payload: R.Remote,
                                   metadata: Metadata? = nil,
                                   parse: () throws -> R.Local) rethrows -> R.Local {

        return try measure(with: makeParseIdentifier(for: resource, payload: payload),
                           metadata: metadata,
                           execute: parse)
    }
}
