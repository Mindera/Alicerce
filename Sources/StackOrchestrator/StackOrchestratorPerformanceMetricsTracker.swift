import Foundation

public protocol StackOrchestratorPerformanceMetricsTracker: PerformanceMetricsTracker {

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
    ///   - result: The decode's result type.
    /// - Returns: The new resource decode metric's identifier.
    func makeDecodeIdentifier<R, P, T>(for resource: R, payload: P?, result: T.Type) -> Identifier

    /// Creates a new metadata to be used by a decoding performance metric, for a given `Resource` (and optional
    /// payload).
    ///
    /// - Parameters:
    ///   - resource: The resource to create the metadata for.
    ///   - payload: The resource's payload.
    ///   - result: The decode's result type.
    /// - Returns: The new resource decode metric's identifier.
    func makeDecodeMetadata<R, P, T>(for resource: R, payload: P?, result: T.Type) -> Metadata?

    /// Measures a given `Resource`'s parsing execution time.
    ///
    /// - Parameters:
    ///   - resource: The resource being decoded.
    ///   - payload: The resource's received payload.
    ///   - metadata: The parse metric's metadata dictionary.
    ///   - decode: The resource's decoding closure, to measure the execution time of.
    /// - Returns: The parsing result, if any.
    /// - Throws: The parsing error, if any.
    func measureDecode<R, P, T>(of resource: R, payload: P, decode: () throws -> T) rethrows -> T
}

public extension StackOrchestratorPerformanceMetricsTracker {

    var modelTypeMetadataKey: Metadata.Key { return "model_type" }
    var payloadSizeMetadataKey: Metadata.Key { return "payload_size" }

    func makeDecodeIdentifier<R, P, T>(for resource: R, payload: P?, result: T.Type = T.self) -> Identifier {
        return "Decode \(T.self)"
    }

    func makeDecodeMetadata<R, P, T>(for resource: R, payload: P?, result: T.Type) -> Metadata? {
        return [modelTypeMetadataKey : "\(result.self)"]
    }

    func measureDecode<R, P, T>(of resource: R, payload: P, decode: () throws -> T) rethrows -> T {

        return try measure(
            with: makeDecodeIdentifier(for: resource, payload: payload, result: T.self),
            metadata: makeDecodeMetadata(for: resource, payload: payload, result: T.self),
            execute: decode
        )
    }
}
