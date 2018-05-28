import Foundation

public protocol RequestInterceptor {
    func intercept(request: URLRequest)
    func intercept(response: URLResponse?, data: Data?, error: Error?, for request: URLRequest)
}
