import Foundation
import Result

/// A type that tracks performance metrics.
public protocol PerformanceMetricsTracker: AnyObject {

    /// A metric unique tag.
    typealias Tag = PerformanceMetrics.Tag

    /// A metric identifier.
    typealias Identifier = PerformanceMetrics.Identifier

    /// A metric metadata dictionary.
    typealias Metadata = PerformanceMetrics.Metadata

    /// Starts measuring the execution time of a specific code block identified by a particular identifier.
    ///
    /// - Parameters:
    ///   - identifier: The metric's identifier, to group multiple metrics on the provider.
    /// - Returns: A token that uniquely identifies the current metric instance.
    func start(with identifier: Identifier) -> Token<Tag>

    /// Stops measuring the execution of a specific code block while attaching any additional metric metadata.
    ///
    /// - Parameters:
    ///   - token: The metric's identifying token, returned by `start(with:)`.
    ///   - metadata: The metric's metadata dictionary.
    func stop(with token: Token<Tag>, metadata: Metadata?)

    /// Measures a given closure's execution time once it returns or throws (i.e. *synchronously*). An optional metadata
    /// dictionary can be provided to be associated with the recorded metric.
    ///
    /// - Parameters:
    ///   - identifier: The metric's identifier.
    ///   - metadata: The metric's metadata dictionary. The default is `nil`.
    ///   - execute: The closure to measure the execution time of.
    /// - Returns: The closure's return value, if any.
    /// - Throws: The closure's thrown error, if any.
    @discardableResult
    func measure<T>(with identifier: Identifier, metadata: Metadata?, execute: () throws -> T) rethrows -> T

    /// Measures a given closure's execution time *until* an inner `stop` closure is invoked by it with an optional
    /// metadata dictionary to be associated with the recorded metric.
    ///
    /// Should be used for asynchronous code, or when the metric metadata is only available during execution.
    ///
    /// - Important: The `stop` closure should be called *before* the `execute` either returns or throws.
    ///
    /// - Parameters:
    ///   - identifier: The metric's identifier.
    ///   - execute: The closure to measure the execution time of.
    ///   - stop: The closure to be invoked by `execute` to stop measuring the execution time, along with any additional
    /// metric metadata.
    ///   - metadata: The metric's metadata dictionary.
    /// - Returns: The closure's return value, if any.
    /// - Throws: The closure's thrown error, if any.
    @discardableResult
    func measure<T>(with identifier: Identifier,
                    execute: (_ stop: @escaping (_ metadata: Metadata?) -> Void) throws -> T) rethrows -> T
}

public extension PerformanceMetricsTracker {

    @discardableResult
    func measure<T>(with identifier: Identifier, metadata: Metadata? = nil, execute: () throws -> T) rethrows -> T {

        let token = start(with: identifier)
        defer { stop(with: token, metadata: metadata) }

        let measureResult = try execute()

        return measureResult
    }

    @discardableResult
    func measure<T>(with identifier: Identifier,
                    execute: (_ stop: @escaping (_ metadata: Metadata?) -> Void) throws -> T) rethrows -> T {

        let token = start(with: identifier)

        return try execute { [weak self] in
            self?.stop(with: token, metadata: $0)
        }
    }
}
