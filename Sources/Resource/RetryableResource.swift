import Foundation

/// A type representing a resource that can be retried after failing.
public protocol RetryableResource {

    /// A type that represents a received remote payload.
    associatedtype Remote

    /// A type that represents a network request.
    associatedtype Request

    /// A type that represents a network response.
    associatedtype Response

    /// The resource's specialized retry policy.
    typealias RetryPolicy = ResourceRetry.Policy<Remote, Request, Response>

    /// The errors that have occurred on each retry.
    var retryErrors: [Error] { get set }

    /// The total amount of delay that has been used on retries. Only the *scheduled* retry delay should be counted.
    var totalRetriedDelay: ResourceRetry.Delay { get set }

    /// The retry policies used to evaluate which action to take when an error occurs.
    var retryPolicies: [RetryPolicy] { get }

    /// Evaluates if a resource's fetch should be retried after having failed, according to the defined retry policies.
    ///
    /// - Parameters:
    ///   - request: The request that originated the error.
    ///   - error: The error that occurred.
    ///   - payload: The received remote payload.
    ///   - response: The received response
    /// - Returns: The action to take.
    func shouldRetry(with request: Request, error: Error, payload: Remote?, response: Response?) -> ResourceRetry.Action
}

public extension RetryableResource {

    /// The number of times a resource has been retried (according to the retried after errors).
    var numRetries: Int { return retryErrors.count }

    func shouldRetry(with request: Request,
                     error: Error,
                     payload: Remote?,
                     response: Response?) -> ResourceRetry.Action {

        guard retryPolicies.isEmpty == false else { return .none }

        var candidateAction: ResourceRetry.Action = .none

        for policy in retryPolicies {
            let action = policy.shouldRetry(previousErrors: retryErrors,
                                            totalDelay: totalRetriedDelay,
                                            request: request,
                                            error: error,
                                            payload: payload,
                                            response: response)

            switch (action, candidateAction) {
            case (.noRetry, _):
                // exit immediately if any policy does not allow retry
                return action
            case (.retry, .none), (.retryAfter, .none), (.retryAfter, .retry):
                // `retry` and `retryAfter prevail over `.none`, `retryAfter` prevails over `retry`
                candidateAction = action
            case (.retryAfter(let newDelay), .retryAfter(let candidateDelay)) where newDelay > candidateDelay:
                // `retryAfter` with the longer delay prevails
                candidateAction = action
            default:
                // do nothing on all other cases
                break
            }
        }

        return candidateAction
    }
}
