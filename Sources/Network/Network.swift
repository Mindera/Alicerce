import Foundation
import Result

public enum Network {

    // MARK: - TypeAlias

    public typealias CompletionClosure<R> = (Result<Value<R>, Error>) -> Void
    public typealias AuthenticationCompletionClosure = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    // MARK: - Response value

    public struct Value<R> {

        public let value: R
        public let response: URLResponse

        public init(value: R, response: URLResponse) {
            self.value = value
            self.response = response
        }
    }

    // MARK: - Response error

    public enum Error: Swift.Error {

        case noRequest(Swift.Error)
        case http(code: HTTP.StatusCode, apiError: Swift.Error?, response: URLResponse)
        case noData(response: URLResponse)
        case url(Swift.Error, response: URLResponse?)
        case badResponse(response: URLResponse?)
        case retry(errors: [Swift.Error],
                   totalDelay: ResourceRetry.Delay,
                   retryError: ResourceRetry.Error,
                   response: URLResponse?)
    }

    // MARK: - Network Configuration

    public struct Configuration {

        let authenticationChallengeHandler: AuthenticationChallengeHandler?

        let requestInterceptors: [RequestInterceptor]

        let retryQueue: DispatchQueue

        public init(authenticationChallengeHandler: AuthenticationChallengeHandler? = nil,
                    requestInterceptors: [RequestInterceptor] = [],
                    retryQueue: DispatchQueue) {

            self.authenticationChallengeHandler = authenticationChallengeHandler
            self.requestInterceptors = requestInterceptors
            self.retryQueue = retryQueue
        }
    }
}

extension Network.Error {
    var response: URLResponse? {
        switch self {
        case .noRequest:
            return nil
        case let .http(_, _, response):
            return response
        case let .noData(response):
            return response
        case let .url(_, response):
            return response
        case let .badResponse(response):
            return response
        case let .retry(_, _, _, response):
            return response
        }
    }
}
