import Foundation

/// A type representing the resource retry namespace (case-less enum).
public enum ResourceRetry {

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

    /// A number of retries.
    public typealias Retries = Int

    /// An amount of delay time.
    public typealias Delay = TimeInterval

    /// A retry policy.
    public enum Policy<Remote, Request, Response> {

        /// A policy that limits the total number of retries.
        case retries(Retries)

        /// A policy that applies a backoff strategy to delay and limit retries. See `Backoff` for more details on the
        /// available strategies.
        case backoff(Backoff)

        /// A policy that applies a custom rule. See `Rule` for more details on the rule closure signature.
        case custom(Rule)

        /// A custom policy rule.
        ///
        /// - Parameters:
        ///   - previousErrors: The errors that have occured so far (i.e. have resulted in a previous retry), excluding
        /// the current error.
        ///   - totalDelay: The total amount of delay that has been used on retries.
        ///   - request: The request that originated the error.
        ///   - error: The error that occurred.
        ///   - payload: The received remote payload.
        ///   - response: The received response
        /// - Returns: The action to take.
        public typealias Rule = (_ previousErrors: [Swift.Error],
                                 _ totalDelay: Delay,
                                 _ request: Request,
                                 _ error: Swift.Error,
                                 _ payload: Remote?,
                                 _ response: Response?) -> Action

        /// A backoff strategy that defines an amount of time for each retry, as well as a truncation mechanism to
        /// limit the retries (either by number of retries, or total delay time).
        public enum Backoff {

            /// A backoff strategy that delays each retry by a constant amount of time, while a truncation rule allows.
            /// See `Backoff.Truncation` for more details on the available truncation rules.
            case constant(Delay, Truncation)

            /// A backoff strategy that delays each retry according to a scaling function (typically exponential)
            /// calculated from a base delay, while a truncation rule allows. See `Backoff.Truncation` for more details
            /// on the available truncation rules.
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
                case retries(Retries)

                /// A rule that limits the total amount of *scheduled* delay time used by retries.
                /// - Note: When used in conjunction with an `Backoff.exponential` strategy, the resulting delay for
                /// each retry will be the *minimum* between the scaling function's output and the configured maximum.
                case delay(Delay)
            }
        }

        /// Evaluates the policy to determine if a retry should be made under the current circumstances.
        ///
        /// - Parameters:
        ///   - previousErrors: The errors that have occured so far (i.e. have resulted in a previous retry), excluding
        /// the current error.
        ///   - totalDelay: The total amount of delay that has been used on retries.
        ///   - request: The request that originated the error.
        ///   - error: The error that occurred.
        ///   - payload: The received remote payload.
        ///   - response: The received response
        /// - Returns: The action to take.
        public func shouldRetry(previousErrors: [Swift.Error],
                                totalDelay: Delay,
                                request: Request,
                                error: Swift.Error,
                                payload: Remote?,
                                response: Response?) -> Action {

            let numRetries = previousErrors.count

            switch self {
            case .retries(let max) where numRetries >= max,
                 .backoff(.constant(_, .retries(let max))) where numRetries >= max,
                 .backoff(.exponential(_, _, .retries(let max))) where numRetries >= max:
                return .noRetry(.retries(max))
            case .backoff(.constant(_, .delay(let max))) where totalDelay >= max,
                 .backoff(.exponential(_, _, .delay(let max))) where totalDelay >= max:
                return .noRetry(.delay(max))
            case .retries:
                return .retry
            case .backoff(.constant(let delay, _)):
                return .retryAfter(delay)
            case .backoff(.exponential(let base, let scale, .delay(let max))):
                return .retryAfter(.minimum(scale(base, numRetries), max))
            case .backoff(.exponential(let base, let scale, _)):
                return .retryAfter(scale(base, numRetries))
            case .custom(let rule):
                return rule(previousErrors, totalDelay, request, error, payload, response)
            }
        }
    }
}
