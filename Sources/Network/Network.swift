import Foundation
import Result

public enum Network {

    // MARK: - TypeAlias

    public typealias CompletionClosure<R> = (Result<R, Error>) -> Void
    public typealias AuthenticationCompletionClosure = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    // MARK: - Network Error

    public enum Error: Swift.Error {
        case http(code: HTTP.StatusCode, apiError: Swift.Error?)
        case noData
        case url(Swift.Error)
        case badResponse
        case authenticator(Swift.Error)
        case retry(errors: [Swift.Error], totalDelay: ResourceRetry.Delay, retryError: ResourceRetry.Error)
    }

    // MARK: - Network Configuration

    public struct Configuration {

        let authenticationChallengeHandler: AuthenticationChallengeHandler?

        let authenticator: NetworkAuthenticator?

        let requestInterceptors: [RequestInterceptor]

        let retryQueue: DispatchQueue

        public init(authenticationChallengeHandler: AuthenticationChallengeHandler? = nil,
                    authenticator: NetworkAuthenticator? = nil,
                    requestInterceptors: [RequestInterceptor] = [],
                    retryQueue: DispatchQueue) {
            self.authenticationChallengeHandler = authenticationChallengeHandler
            self.authenticator = authenticator
            self.requestInterceptors = requestInterceptors
            self.retryQueue = retryQueue
        }
    }
}
