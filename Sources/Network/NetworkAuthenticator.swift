import Foundation
import Result

public protocol NetworkAuthenticator: class {

    typealias PerformRequestClosure = (Result<URLRequest, AnyError>) -> Cancelable

    func authenticate(request: URLRequest, performRequest: @escaping PerformRequestClosure) -> Cancelable
}

public protocol RetryableNetworkAuthenticator: NetworkAuthenticator {

    typealias RetryPolicy = ResourceRetry.Policy<Data, URLRequest, URLResponse>

    func retryPolicyRule() -> RetryPolicy.Rule
}
