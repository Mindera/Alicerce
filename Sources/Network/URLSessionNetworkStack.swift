import Foundation
import Result

public extension Network {

    final class URLSessionNetworkStack: NSObject, NetworkStack, URLSessionDelegate {

        public typealias Remote = Data
        public typealias Request = URLRequest
        public typealias Response = URLResponse

        public typealias URLSessionDataTaskClosure = (Data?, URLResponse?, Swift.Error?) -> Void

        private let authenticationChallengeHandler: AuthenticationChallengeHandler?
        private let authenticator: NetworkAuthenticator?
        private let requestInterceptors: [RequestInterceptor]
        private let retryQueue: DispatchQueue

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

        public init(authenticationChallengeHandler: AuthenticationChallengeHandler? = nil,
                    authenticator: NetworkAuthenticator? = nil,
                    requestInterceptors: [RequestInterceptor] = [],
                    retryQueue: DispatchQueue) {
            self.authenticationChallengeHandler = authenticationChallengeHandler
            self.authenticator = authenticator
            self.requestInterceptors = requestInterceptors
            self.retryQueue = retryQueue
        }

        public convenience init(configuration: Network.Configuration) {
            self.init(authenticationChallengeHandler: configuration.authenticationChallengeHandler,
                      authenticator: configuration.authenticator,
                      requestInterceptors: configuration.requestInterceptors,
                      retryQueue: configuration.retryQueue)
        }

        @discardableResult
        public func fetch<R>(resource: R, completion: @escaping Network.CompletionClosure<R.Remote>)
        -> Cancelable
        where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response {

            guard let authenticator = authenticator else {
                let request = resource.request

                return perform(request: request,
                               resource: resource,
                               apiErrorParser: resource.errorParser,
                               completion: completion)
            }

            return authenticatedFetch(using: authenticator,
                                      resource: resource,
                                      apiErrorParser: resource.errorParser,
                                      completion: completion)
        }

        // MARK: - URLSessionDelegate Methods

        public func urlSession(_ session: URLSession,
                               didReceive challenge: URLAuthenticationChallenge,
                               completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

            if let handler = authenticationChallengeHandler {
                return handler.handle(challenge, completionHandler: completionHandler)
            }

            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }

        // MARK: - Private Methods

        private func perform<R, E>(request: URLRequest,
                                   resource: R,
                                   apiErrorParser: @escaping ResourceErrorParseClosure<R.Remote, E>,
                                   completion: @escaping Network.CompletionClosure<R.Remote>)
        -> Cancelable
        where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response,
              E: Swift.Error {

            guard let session = session else {
                fatalError("🔥: session is `nil`! Forgot to 💉?")
            }

            requestInterceptors.forEach {
                $0.intercept(request: request)
            }

            let cancelableBag = CancelableBag()

            let task = session.dataTask(with: request,
                                        completionHandler: handleHTTPResponse(with: completion,
                                                                              request: request,
                                                                              resource: resource,
                                                                              cancelableBag: cancelableBag,
                                                                              apiErrorParser: apiErrorParser))

            cancelableBag.add(cancelable: WeakCancelable(task))

            task.resume()

            return cancelableBag
        }

        private func handleHTTPResponse<R, E>(with completion: @escaping Network.CompletionClosure<R.Remote>,
                                              request: Request,
                                              resource: R,
                                              cancelableBag: CancelableBag,
                                              apiErrorParser: @escaping ResourceErrorParseClosure<R.Remote, E>)
        -> URLSessionDataTaskClosure
        where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response,
              E: Swift.Error {

            return { [weak self] data, response, error in
                guard let strongSelf = self else { return }

                strongSelf.requestInterceptors.forEach {
                    $0.intercept(response: response, data: data, error: error, for: request)
                }

                // handle any "regular" error and define the action to take (none, retry, retry after, no retry)
                if let error = error {
                    strongSelf.handleError(with: completion,
                                           request: request,
                                           error: error,
                                           payload: data,
                                           response: response,
                                           resource: resource,
                                           cancelableBag: cancelableBag)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    // don't retry this error since this should "never" happen
                    completion(.failure(.badResponse))
                    return
                }

                let httpStatusCode = HTTP.StatusCode(httpResponse.statusCode)
                var networkError: Error?

                switch (httpStatusCode, data) {
                case (.success, let remoteData?):
                    completion(.success(remoteData))
                case (.success(204), nil) where R.Local.self == Void.self:
                    completion(.success(R.empty))
                case (.success, _):
                    networkError = .noData
                case let (statusCode, remoteData?):
                    networkError = .http(code: statusCode, apiError: apiErrorParser(remoteData))
                case (let statusCode, _):
                    networkError = .http(code: statusCode, apiError: nil)
                }

                // handle any "network" error and define the action to take (none, retry, retry after, no retry)
                if let networkError = networkError {
                    strongSelf.handleError(with: completion,
                                           request: request,
                                           error: networkError,
                                           payload: data,
                                           response: response,
                                           resource: resource,
                                           cancelableBag: cancelableBag)
                }
            }
        }

        private func authenticatedFetch<R, E>(using authenticator: NetworkAuthenticator,
                                              resource: R,
                                              apiErrorParser: @escaping ResourceErrorParseClosure<R.Remote, E>,
                                              completion: @escaping Network.CompletionClosure<R.Remote>) -> Cancelable
        where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response,
              E: Swift.Error {

            let request = resource.request

            return authenticator.authenticate(request: request) { [weak self] result -> Cancelable in

                guard let strongSelf = self else { return DummyCancelable() }

                switch result {
                case let .success(authenticatedRequest):
                    return strongSelf.perform(request: authenticatedRequest,
                                              resource: resource,
                                              apiErrorParser: apiErrorParser,
                                              completion: completion)

                case let .failure(error):
                    completion(.failure(.authenticator(error.error)))

                    return DummyCancelable()
                }
            }
        }

        private func handleError<R>(with completion: @escaping Network.CompletionClosure<R.Remote>,
                                    request: Request,
                                    error: Swift.Error,
                                    payload: Data?,
                                    response: Response?,
                                    resource: R,
                                    cancelableBag: CancelableBag)
        where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response {

            let action = resource.shouldRetry(with: request, error: error, payload: payload, response: response)

            var resource = resource
            resource.retryErrors.append(error)

            switch (action, error) {
            case (.none, let networkError as Error):
                completion(.failure(networkError))
            case (.none, _):
                completion(.failure(.url(error)))
            case (.retry, _):
                let retryCancelable = fetch(resource: resource, completion: completion)

                cancelableBag.add(cancelable: retryCancelable)
            case (.retryAfter(let delay), _):
                resource.totalRetriedDelay += delay

                let fetchWorkItem = DispatchWorkItem { [weak self] in
                    if let retryCancelable = self?.fetch(resource: resource, completion: completion) {
                        cancelableBag.add(cancelable: retryCancelable)
                    }
                }

                cancelableBag.add(cancelable: WeakCancelable(fetchWorkItem))

                let nanos = Int(delay * Double(NSEC_PER_SEC))

                retryQueue.asyncAfter(deadline: .now() + .nanoseconds(nanos), execute: fetchWorkItem)
            case (.noRetry(let retryError), _):
                completion(.failure(.retry(errors: resource.retryErrors,
                                           totalDelay: resource.totalRetriedDelay,
                                           retryError: retryError)))
            }

        }
    }
}
