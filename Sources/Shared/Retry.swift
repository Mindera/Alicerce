import Foundation

/// A type representing the retry namespace (case-less enum).
public enum Retry {

    /// An action to take after evaluating a retry policy.
    public enum Action {

        /// No retry action should be taken, and normal error handling should be made.
        case none

        /// The resource shouldn't be retried, due to an error.
        case noRetry(Error)

        /// The resource should be retried *immediately*.
        case retry

        /// The resource should be retried *after* the specified delay.
        case retryAfter(Delay)

        /// A closure to compare actions.
        public typealias CompareClosure = (Action, Action) -> Action
    }

    /// An error produced during retry policy evaluation, when a retry shouldn't be made (i.e. on `Action.noRetry`).
    public enum Error: Swift.Error {

        /// The maximum retries of a policy have been reached.
        case retries(Retries)

        /// The maximum delay of a policy has been reached.
        case delay(Delay)

        /// An arbitrary error prevented the resource from being retried.
        case custom(Swift.Error)
    }

    // A retry state of an arbitrary operation.
    public struct State {

        /// The errors that have occurred on each retry.
        public var errors: [Swift.Error]

        /// The total amount of delay that has been used on retries. Only the *scheduled* retry delay should be counted.
        public var totalDelay: Retry.Delay

        /// An empty (initial) state.
        public static let empty = Retry.State(errors: [], totalDelay: 0)

        /// The total number of attempts made.
        public var attemptCount: Int { errors.count + 1 }

        /// The total number of retries made.
        public var retryCount: Int { errors.count }
    }

    /// A number of retries.
    public typealias Retries = Int

    /// An amount of delay time.
    public typealias Delay = TimeInterval

    /// A retry policy.
    public enum Policy<Metadata> {

        /// A policy that limits the total number of retries.
        case maxRetries(Retries)

        /// A policy that applies a backoff strategy to delay and limit retries. See `Backoff` for more details on the
        /// available strategies.
        case backoff(Backoff)

        /// A policy that applies a custom rule. See `Rule` for more details on the rule closure signature.
        case custom(Rule)

        /// A custom policy rule.
        ///
        /// - Parameters:
        ///   - error: The error that occurred.
        ///   - state: The retry state, containing:
        ///     + errors that have occured so far (i.e. have resulted in a previous retry), excluding the current error.
        ///     + the total amount of delay that has been used on retries.
        ///   - metadata: The error event metadata (e.g. request, payload, response).
        /// - Returns: The action to take.
        public typealias Rule = (_ error: Swift.Error, _ state: Retry.State, _ metadata: Metadata) -> Action

        /// A backoff strategy that defines an amount of time for each retry, as well as a truncation mechanism to
        /// limit the retries (either by number of retries, or total delay time).
        public enum Backoff {

            /// A backoff strategy that delays each retry by a constant amount of time, while a truncation rule allows
            /// it. See `Backoff.Truncation` for more details on the available truncation rules.
            case constant(Delay, Truncation)

            /// A backoff strategy that delays each retry according to a scaling function (typically exponential)
            /// calculated from a base delay, while a truncation rule allows it. See `Backoff.Truncation` for more
            /// details on the available truncation rules.
            case exponential(Delay, Scale, Truncation)

            /// An exponential backoff scaling function, which takes into consideration the base delay and current
            /// retries to calculate (scale) each retry's delay.
            ///
            /// - Parameters:
            ///   - baseDelay: The base delay of the strategy.
            ///   - numRetries: The number of retries.
            /// - Returns: The delay time to use for the next retry.
            public typealias Scale = (_ baseDelay: Delay, _ numRetries: Retries) -> Delay

            /// A backoff strategy truncation rule, to limit retries.
            public enum Truncation {

                /// A rule that limits the total number of retries.
                case maxRetries(Retries)

                /// A rule that limits the total amount of *scheduled* delay time used by retries.
                /// - Note: When used in conjunction with an `Backoff.exponential` strategy, the resulting delay for
                /// each retry will be the *minimum* between the scaling function's output and the configured maximum.
                case maxDelay(Delay)
            }
        }

        /// Evaluates the policy to determine if a retry should be made under the current circumstances.
        ///
        /// - Parameters:
        ///   - error: The error that occurred.
        ///   - state: The retry state, containing:
        ///     + errors that have occured so far (i.e. have resulted in a previous retry), excluding the current error.
        ///     + the total amount of delay that has been used on retries.
        ///   - metadata: The error event metadata (e.g. request, payload, response).
        /// - Returns: The action to take.
        public func shouldRetry(with error: Swift.Error, state: Retry.State, metadata: Metadata) -> Action {

            let retryCount = state.retryCount

            switch self {
            case .maxRetries(let max) where retryCount >= max,
                 .backoff(.constant(_, .maxRetries(let max))) where retryCount >= max,
                 .backoff(.exponential(_, _, .maxRetries(let max))) where retryCount >= max:
                return .noRetry(.retries(max))

            case .backoff(.constant(_, .maxDelay(let max))) where state.totalDelay >= max,
                 .backoff(.exponential(_, _, .maxDelay(let max))) where state.totalDelay >= max:
                return .noRetry(.delay(max))

            case .maxRetries:
                return .retry

            case .backoff(.constant(let delay, _)):
                return .retryAfter(delay)

            case .backoff(.exponential(let base, let scale, .maxDelay(let max))):
                return .retryAfter(.minimum(scale(base, retryCount), max))

            case .backoff(.exponential(let base, let scale, _)):
                return .retryAfter(scale(base, retryCount))

            case .custom(let rule):
                return rule(error, state, metadata)
            }
        }
    }
}

extension Retry.Action {

    /// Compares two actions and returns the most prioritary one.
    ///
    /// The retry action priorities are:
    /// - A `.noRetry` prevails over any other action.
    /// - A `.retry` and `.retryAfter` prevail over `.none`
    /// - A `.retryAfter` prevails over `.retry`.
    /// - The `.retryAfter` with the longer delay prevails.
    ///
    /// - Parameters:
    ///   - lhs: The first action to compare.
    ///   - rhs: The second action to compare.
    public static func mostPrioritary(_ lhs: Retry.Action, _ rhs: Retry.Action) -> Retry.Action {

        switch (lhs, rhs) {
        // `.noRetry` prevails over any other action
        case (.noRetry, _):
            return lhs

        case (_, .noRetry):
            return rhs

        // `retry` and `retryAfter` prevail over `.none`, `retryAfter` prevails over `retry`
        case (.retry, .none),
             (.retryAfter, .none),
             (.retryAfter, .retry):
            return lhs

        case (.none, .retry),
             (.none, .retryAfter),
             (.retry, .retryAfter):
            return rhs

        // `retryAfter` with the longer delay prevails
        case (.retryAfter(let lhsDelay), .retryAfter(let rhsDelay)):
            return lhsDelay > rhsDelay ? lhs : rhs

        case (.none, .none):
            return .none

        case (.retry, .retry):
            return .retry
        }
    }
}
