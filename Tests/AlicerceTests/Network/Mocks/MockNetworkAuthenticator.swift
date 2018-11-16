import Foundation
import Result
@testable import Alicerce

final class MockNetworkAuthenticator: NetworkAuthenticator, RetryableNetworkAuthenticator {

    enum Error: Swift.Error {
        case 🚫
    }

    var mockAuthenticateClosure: ((URLRequest) -> Result<URLRequest, AnyError>)?
    var mockRetryPolicyRule: RetryPolicy.Rule = { _, _, _, _, _, _ in .noRetry(.custom(Error.🚫)) }

    func authenticate(request: URLRequest,
                      performRequest: @escaping NetworkAuthenticator.PerformRequestClosure) -> Cancelable {

        return performRequest(mockAuthenticateClosure?(request) ?? .success(request))
    }

    func retryPolicyRule() -> RetryPolicy.Rule { return mockRetryPolicyRule }
}
