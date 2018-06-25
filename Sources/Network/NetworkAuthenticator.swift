import Foundation
import Result

public protocol NetworkAuthenticator {
    typealias PerformRequestClosure = (Result<URLRequest, AnyError>) -> Cancelable

    func authenticate(request: URLRequest, performRequest: @escaping PerformRequestClosure) -> Cancelable

    func isAuthenticationInvalid(for request: URLRequest,
                                 data: Data?,
                                 response: HTTPURLResponse?,
                                 error: Swift.Error?) -> Bool
}
