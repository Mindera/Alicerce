import Foundation
@testable import Alicerce

final class MockRequestInterceptor: RequestInterceptor {
    var interceptRequestClosure: ((URLRequest) -> Void)?
    var interceptResponseClosure: ((URLResponse?, Data?, Error?, URLRequest?) -> Void)?

    func intercept(request: URLRequest) {
        interceptRequestClosure?(request)
    }
    func intercept(response: URLResponse?, data: Data?, error: Error?, for request: URLRequest) {
        interceptResponseClosure?(response, data, error, request)
    }
}
