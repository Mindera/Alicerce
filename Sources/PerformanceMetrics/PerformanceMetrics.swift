import Foundation

/// A type representing the Analytics namespace (case-less enum).
public enum PerformanceMetrics {

    /// A phantom type representing a performance metric's instance tag (used on the `Token`'s).
    public enum Tag {}

    /// A metric identifier.
    public typealias Identifier = String

    /// A metric metadata dictionary.
    public typealias Metadata = [String : Any]

    /// A performance metrics tracker that forwards performance measuring events to multiple trackers, while not doing
    /// any tracking on its own.
    public class MultiTracker: PerformanceMetricsTracker {

        /// The configured sub trackers.
        public let trackers: [PerformanceMetricsTracker]

        /// The tracker's tokenizer.
        private let tokenizer = Tokenizer<Tag>()

        /// The tracker's token dictionary, containing the mapping between internal and sub trackers' tokens.
        private let tokens = Atomic<[Token<Tag> : [Token<Tag>]]>([:])

        /// Creates a new performance metrics multi trcker instance, with the specified sub trackers.
        ///
        /// - Parameters:
        ///   -trackers: The sub trackers to forward performance measuring events to.
        public init(trackers: [PerformanceMetricsTracker]) {
            assert(trackers.isEmpty == false, "🙅‍♂️: trackers shouldn't be empty, since it renders this tracker useless!")

            self.trackers = trackers
        }

        // MARK: - PerformanceMetricsTracker

        /// Starts measuring the execution time of a specific code block identified by a particular identifier, by
        /// propagating it to all registered sub tracker.
        ///
        /// - Parameters:
        ///   - identifier: The metric's identifier, to group multiple metrics on the provider.
        /// - Returns: A token identifying this particular metric instance.
        public func start(with identifier: Identifier) -> Token<Tag> {

            let token = tokenizer.next
            let subTokens = startTrackers(with: identifier)

            tokens.modify { $0[token] = subTokens }

            return token
        }

        /// Stops measuring the execution of a specific code block while attaching any additional metric metadata, by
        /// propagating it to all registered sub trackers.
        ///
        /// - Parameters:
        ///   - token: The metric's identifying token, returned by `start(with:)`.
        ///   - metadata: The metric's metadata dictionary.
        public func stop(with token: Token<Tag>, metadata: Metadata? = nil) {

            guard let subTokens = tokens.modify({ $0.removeValue(forKey: token) }) else {
                assertionFailure("🔥: missing sub tokens for token \(token)!")
                return
            }

            stopTrackers(with: subTokens, metadata: metadata)
        }

        /// Measures a given closure's execution time once it returns or throws (i.e. *synchronously*). An optional
        /// metadata dictionary can be provided to be associated with the recorded metric. The metric is calculated on
        /// all sub trackers.
        ///
        /// - Parameters:
        ///   - identifier: The metric's identifier.
        ///   - metadata: The metric's metadata dictionary. The default is `nil`.
        ///   - execute: The closure to measure the execution time of.
        /// - Returns: The closure's return value, if any.
        /// - Throws: The closure's thrown error, if any.
        @discardableResult
        public func measure<T>(with identifier: Identifier,
                               metadata: Metadata? = nil,
                               execute: () throws -> T) rethrows -> T {

            let subTokens = startTrackers(with: identifier)
            defer { stopTrackers(with: subTokens, metadata: metadata) }

            let measureResult = try execute()

            return measureResult
        }

        /// Measures a given closure's execution time *until* an inner `stop` closure is invoked by it with an optional
        /// metadata dictionary to be associated with the recorded metric. The metric is calculated on all sub trackers.
        ///
        /// Should be used for asynchronous code, or when the metric metadata is only available during execution.
        ///
        /// - Important: The `stop` closure should be called *before* the `execute` either returns or throws.
        ///
        /// - Parameters:
        ///   - identifier: The metric's identifier.
        ///   - execute: The closure to measure the execution time of.
        ///   - stop: The closure to be invoked by `execute` to stop measuring the execution time, along with any
        /// additional metric metadata.
        ///   - metadata: The metric's metadata dictionary.
        /// - Returns: The closure's return value, if any.
        /// - Throws: The closure's thrown error, if any.
        @discardableResult
        public func measure<T>(with identifier: Identifier,
                               execute: (_ stop: @escaping (_ metadata: Metadata?) -> Void) throws -> T) rethrows -> T {

            let subTokens = startTrackers(with: identifier)

            return try execute { [weak self] metadata in
                self?.stopTrackers(with: subTokens, metadata: metadata)
            }
        }

        // MARK: - Private

        /// Starts measuring the execution time of a specific code block identified by a particular identifier on all
        /// sub trackers.
        ///
        /// - Parameters:
        ///   - identifier: The metric's identifier.
        /// - Returns: The metric's identifying tokens for each sub tracker, returned by each tracker's `start(with:)`
        /// in the same order as `trackers`.
        private func startTrackers(with identifier: Identifier) -> [Token<Tag>] {

            return trackers.map { $0.start(with: identifier) }
        }

        /// Stops measuring the execution of a specific code block while attaching any additional metric metadata on
        /// all sub trackers.
        ///
        /// - Important: The provided tokens order *must* match the `trackers` order.
        ///
        /// - Parameters:
        ///   - subTokens: The metric's identifying tokens for each sub tracker, returned by each tracker's
        /// `start(with:)`.
        ///   - metadata: The metric's metadata dictionary.
        private func stopTrackers(with subTokens: [Token<Tag>], metadata: Metadata?) {

            assert(subTokens.count == trackers.count, "😱: number of sub tokens and sub trackers must match!")

            zip(trackers, subTokens).forEach { tracker, token in tracker.stop(with: token, metadata: metadata) }
        }

    }
}
