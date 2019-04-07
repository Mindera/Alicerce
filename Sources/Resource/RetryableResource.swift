import Foundation

/// A type representing a resource that can be retried after failing an operation.
public protocol RetryableResource {

    /// The resource's retry metadata (e.g. request, payload, response).
    associatedtype RetryMetadata

    /// The resource's specialized retry policy.
    typealias RetryPolicy = Retry.Policy<RetryMetadata>

    /// The errors that have occurred on each retry.
    var retryErrors: [Error] { get set }

    /// The total amount of delay that has been used on retries. Only the *scheduled* retry delay should be counted.
    var totalRetriedDelay: Retry.Delay { get set }

    /// The retry policies used to evaluate which action to take when an error occurs.
    var retryPolicies: [RetryPolicy] { get }

    /// Evaluates if a resource's operation should be retried after failing, according to the defined retry policies.
    ///
    /// - Parameters:
    ///   - error: The error that occurred.
    ///   - metadata: The error event metadata (e.g. request, payload, response).
    /// - Returns: The action to take.
    func shouldRetry(with error: Error, metadata: RetryMetadata) -> Retry.Action
}

public extension RetryableResource {

    /// The number of times a resource has been retried (according to the retried after errors).
    var numRetries: Int { return retryErrors.count }

    func shouldRetry(with error: Error, metadata: RetryMetadata) -> Retry.Action {

        guard retryPolicies.isEmpty == false else { return .none }

        var candidateAction: Retry.Action = .none

        for policy in retryPolicies {
            let action = policy.shouldRetry(with: error,
                                            previousErrors: retryErrors,
                                            totalDelay: totalRetriedDelay,
                                            metadata: metadata)

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

/// A type representing a network resource that can be retried after failing.
public protocol RetryableNetworkResource: RetryableResource & NetworkResource
where RetryMetadata == (request: Request, payload: External?, response: Response?) {}
