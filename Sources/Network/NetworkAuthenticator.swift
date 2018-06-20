import Foundation

public protocol NetworkAuthenticator {
    typealias PerformRequestClosure = (_ inner: () throws -> URLRequest) -> Cancelable

    func authenticate(request: URLRequest, performRequest: @escaping PerformRequestClosure) -> Cancelable

    func isAuthenticationInvalid(for request: URLRequest,
                                 data: Data?,
                                 response: HTTPURLResponse?,
                                 error: Swift.Error?) -> Bool
}
