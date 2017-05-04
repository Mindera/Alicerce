//
//  URLSessionNetworkStack.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Network {

    final class URLSessionNetworkStack: NSObject, NetworkStack, URLSessionDelegate {

        private struct CancelableTask: Cancelable {
            private weak var task: URLSessionTask?

            init(task: URLSessionTask) {
                self.task = task
            }

            public func cancel() {
                task?.cancel()
            }
        }

        private typealias URLSessionDataTaskClosure = (Data?, URLResponse?, Swift.Error?) -> Void

        private let baseURL: URL
        private let authenticationChallengeValidator: AuthenticationChallengeValidatorClosure?

        public var session: URLSession? {
            // In order to define `self` as the session's delegate while preserving dependency injection, the session 
            // must be injected via property. This is because the session's delegate is only defined on its `init`. 🤷‍♂️
            // The session's delegate could be set to `self` using a lazy var (since `self` is already defined), but 
            // then the session couldn't be injected for unit testing.

            willSet(session) {
                guard self.session == nil else {
                    fatalError("🔥: self.session must be `nil`!")
                }

                guard let session = session, session.delegate === self else {
                    fatalError("🔥: session must be non `nil` and \(self) must be its delegate!")
                }
            }
        }

        public init(baseURL: URL, authenticationChallengeValidator: AuthenticationChallengeValidatorClosure? = nil) {
            self.baseURL = baseURL
            self.authenticationChallengeValidator = authenticationChallengeValidator
        }

        public convenience init(configuration: Network.Configuration) {
            self.init(baseURL: configuration.baseURL,
                      authenticationChallengeValidator: configuration.authenticationChallengeValidator)
        }

        @discardableResult
        public func fetch<R: NetworkResource>(resource: R,
                                             _ completion: @escaping Network.CompletionClosure) -> Cancelable {
            guard let session = session else {
                fatalError("🔥: session is `nil`! Forgot to 💉?")
            }

            let request = resource.toRequest(withBaseURL: baseURL)

            let task = session.dataTask(with: request, completionHandler: handleHTTPResponse(with: completion))
            task.resume()

            return CancelableTask(task: task)
        }

        // MARK: - URLSessionDelegate Methods

        public func urlSession(_ session: URLSession,
                               didReceive challenge: URLAuthenticationChallenge,
                               completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

            // TODO: implement proper server trust validation / certificate pinning
            if let validator = authenticationChallengeValidator {
                return validator(challenge, completionHandler)
            }

            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }

        // MARK: - Private Methods

        private func handleHTTPResponse(with completion: @escaping Network.CompletionClosure) -> URLSessionDataTaskClosure {
            return { data, response, error in
                if let error = error {
                    return completion { throw Network.Error.url(error) }
                }

                guard let urlResponse = response as? HTTPURLResponse else {
                    return completion { throw Network.Error.badResponse }
                }

                let httpStatusCode = HTTP.StatusCode(urlResponse.statusCode)

                guard case .success = httpStatusCode else {
                    return completion { throw Network.Error.http(code: httpStatusCode, description: nil) }
                }

                guard let data = data else {
                    return completion { throw Network.Error.noData }
                }
                
                completion { data }
            }
        }
    }
}
