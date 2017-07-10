//
//  URLSessionNetworkStack.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Network {

    public final class CancelableTask: Cancelable {
        private weak var task: URLSessionTask?

        init(task: URLSessionTask) {
            self.task = task
        }

        public func cancel() {
            task?.cancel()
        }
    }

    public final class CancelableBag: Cancelable {
        private lazy var cancelables: [Cancelable] = []

        public init() {}

        public func add(cancelable: Cancelable) {
            cancelables.append(cancelable)
        }

        public func cancel() {
            cancelables.forEach { $0.cancel() }
        }
    }

    public struct NoCancelable: Cancelable {
        public func cancel() {}
    }

    final class URLSessionNetworkStack: NSObject, NetworkStack, URLSessionDelegate {

        private typealias RequestConfig<R: NetworkResource> = (
            resource: R,
            cancelableTask: CancelableTask,
            completion: Network.CompletionClosure
        )

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

            let request = resource.toRequest(withBaseURL: baseURL)

            guard let authenticator = authenticator else {
                return perform(request: request, apiErrorParser: resource.apiErrorParser, completion)
            }

            return networkAuthenticator(authenticator,
                                        perform: request, apiErrorParser: resource.apiErrorParser, completion)
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

        private func perform<E: Swift.Error>(request: URLRequest,
                                             apiErrorParser: @escaping ResourceErrorParseClosure<E>,
                                             _ completion: @escaping Network.CompletionClosure) -> Cancelable {
            guard let session = session else {
                fatalError("🔥: session is `nil`! Forgot to 💉?")
            }

            let cancelableBag = CancelableBag()

            let task = session.dataTask(with: request,
                                        completionHandler: handleHTTPResponse(with: completion,
                                                                              originalRequest: request,
                                                                              cancelableBag: cancelableBag,
                                                                              apiErrorParser: apiErrorParser))

            cancelableBag.add(cancelable: CancelableTask(task: task))

            task.resume()

            return cancelableBag
        }

        private func handleHTTPResponse<E: Swift.Error>(with completion: @escaping Network.CompletionClosure,
                                                        originalRequest: URLRequest,
                                                        cancelableBag: CancelableBag,
                                                        apiErrorParser: @escaping ResourceErrorParseClosure<E>)
        -> URLSessionDataTaskClosure {

            return { [weak self] data, response, error in
                guard let strongSelf = self else { return }

                if let error = error {
                    return completion { throw Network.Error.url(error) }
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    return completion { throw Network.Error.badResponse }
                }

                if let authenticator = strongSelf.authenticator,
                    authenticator.shouldRetry(with: data, response: httpResponse, error: error) {

                    let cancelableRetry = strongSelf.networkAuthenticator(authenticator,
                                                               perform: originalRequest,
                                                               apiErrorParser: apiErrorParser, completion)

                    return cancelableBag.add(cancelable: cancelableRetry)
                }

                let httpStatusCode = HTTP.StatusCode(httpResponse.statusCode)

                guard case .success = httpStatusCode else {

                    let apiError: E? = {
                        guard let data = data else { return nil }
                        return apiErrorParser(data)
                    }()

                    return completion { throw Network.Error.http(code: httpStatusCode, apiError: apiError) }
                }

                guard let data = data else {
                    return completion { throw Network.Error.noData }
                }
                
                completion { data }
            }
        }

        private func networkAuthenticator<E: Swift.Error>(_ authenticator: NetworkAuthenticator,
                                                          perform request: URLRequest,
                                                          apiErrorParser: @escaping ResourceErrorParseClosure<E>,
                                                          _ completion: @escaping Network.CompletionClosure)
        -> Cancelable {

            return authenticator.authenticate(request: request) { [weak self] authenticatedRequest -> Cancelable in

                guard let strongSelf = self else { return NoCancelable() }

                return strongSelf.perform(request: authenticatedRequest, apiErrorParser: apiErrorParser, completion)
            }
        }
    }
}
