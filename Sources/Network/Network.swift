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

        public typealias APIError = Swift.Error
        public typealias TotalRetriedDelay = Retry.Delay

        case noRequest(Swift.Error)
        case http(HTTP.StatusCode, URLResponse)
        case api(APIError, HTTP.StatusCode, URLResponse)
        case noData(URLResponse)
        case url(Swift.Error, URLResponse?)
        case badResponse(URLResponse?)
        case retry(Retry.Error, [Swift.Error], TotalRetriedDelay, URLResponse?)
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

        case .http(_, let response),
            .api(_, _, let response),
            .noData(let response):
            return response

        case .url(_, let response),
             .badResponse(let response),
             .retry(_, _, _, let response):
            return response
        }
    }
}
