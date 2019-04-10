import Foundation
import Result
@testable import Alicerce

final class MockRequestAuthenticator: RetryableURLRequestAuthenticator {

    typealias Request = URLRequest
    typealias Remote = Data
    typealias Response = URLResponse

    enum Error: Swift.Error { case 🚫 }

    var mockAuthenticate: (Request) -> Result<Request, Error> = { .success($0) }
    var mockRetryPolicyRule: RetryPolicy.Rule = { _, _, _, _ in .noRetry(.custom(Error.🚫)) }

    func authenticate(_ request: Request, handler: @escaping AuthenticationHandler) -> Cancelable {

        return handler(mockAuthenticate(request))
    }

    var retryPolicyRule: RetryPolicy.Rule { return mockRetryPolicyRule }
}
