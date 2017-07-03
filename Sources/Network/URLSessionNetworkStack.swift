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

            init(task: URLSessionTask? = nil) {
                self.task = task
            }

            mutating func set(task: URLSessionTask) {
                self.task = task
            }

            public func cancel() {
                task?.cancel()
            }
        }

        private typealias RequestConfig<R: NetworkResource> = (
            resource: R,
            cancelableTask: CancelableTask,
            completion: Network.CompletionClosure
        )

//        private struct RequestConfig<R: NetworkResource> {
//            let resource: R
//            var cancelableTask: CancelableTask
//            let completion: Network.CompletionClosure
//        }

        public typealias URLSessionDataTaskClosure = (Data?, URLResponse?, Swift.Error?) -> Void

        private let baseURL: URL
        private let authenticationChallengeValidator: AuthenticationChallengeValidatorClosure?
        private let authenticator: NetworkAuthenticator?

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

        public init(baseURL: URL,
                    authenticationChallengeValidator: AuthenticationChallengeValidatorClosure? = nil,
                    authenticator: NetworkAuthenticator? = nil) {
            self.baseURL = baseURL
            self.authenticationChallengeValidator = authenticationChallengeValidator
            self.authenticator = authenticator
        }

        public convenience init(configuration: Network.Configuration) {
            self.init(baseURL: configuration.baseURL,
                      authenticationChallengeValidator: configuration.authenticationChallengeValidator,
                      authenticator: configuration.authenticator)
        }

        @discardableResult
        public func fetch<R: NetworkResource>(resource: R,
                                             _ completion: @escaping Network.CompletionClosure) -> Cancelable {
            let cancelableTask = CancelableTask()

            performRequest(with: (resource: resource, cancelableTask: cancelableTask, completion: completion))

            return cancelableTask
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

        private func performRequest<R: NetworkResource>(with config: RequestConfig<R>) {
            guard let session = session else {
                fatalError("🔥: session is `nil`! Forgot to 💉?")
            }

            var (resource, cancelableTask, _) = config

            let request = resource.toRequest(withBaseURL: baseURL)

            authenticate(request: request) { [weak self] request in
                guard let strongSelf = self else { return }

                let task = session.dataTask(with: request,
                                            completionHandler: strongSelf.handleHTTPResponse(for: config))

                cancelableTask.set(task: task)

                task.resume()
            }
        }

        private func authenticate(request: URLRequest, _ completion: @escaping (URLRequest) -> Void) {
            authenticator?.authenticate(request: request, completion) ?? completion(request)
        }

        private func shouldRetry(with data: Data?, response: HTTPURLResponse?, error: Swift.Error?) -> Bool {
            return authenticator?.shouldRetry(with: data, response: response, error: error) ?? false
        }

        private func handleHTTPResponse<R: NetworkResource, E>(for config: RequestConfig<R>)
        -> URLSessionDataTaskClosure where E == R.E {

            let (resource, _, completion) = config

            return { [weak self] data, response, error in
                guard let strongSelf = self else { return }

                if let error = error {
                    return completion { throw Network.Error.url(error) }
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    return completion { throw Network.Error.badResponse }
                }

                if strongSelf.shouldRetry(with: data, response: httpResponse, error: error) {
                    return strongSelf.performRequest(with: config)
                }

                let httpStatusCode = HTTP.StatusCode(httpResponse.statusCode)

                guard case .success = httpStatusCode else {

                    let apiError: E? = {
                        guard let data = data else { return nil }
                        return resource.apiErrorParser(data)
                    }()

                    return completion { throw Network.Error.http(code: httpStatusCode, apiError: apiError) }
                }

                guard let data = data else {
                    return completion { throw Network.Error.noData }
                }
                
                completion { data }
            }
        }
    }
}
