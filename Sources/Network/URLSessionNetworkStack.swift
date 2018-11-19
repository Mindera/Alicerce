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

                return perform(request: request, resource: resource, completion: completion)
            }

            return authenticatedFetch(using: authenticator, resource: resource, completion: completion)
        }

        // MARK: - URLSessionDelegate Methods

        public func urlSession(
            _ session: URLSession,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

            if let handler = authenticationChallengeHandler {
                return handler.handle(challenge, completionHandler: completionHandler)
            }

            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }

        // MARK: - Private Methods

        private func perform<R>(request: URLRequest,
                                resource: R,
                                completion: @escaping Network.CompletionClosure<R.Remote>)
        -> Cancelable
        where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response {

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
                                                                              cancelableBag: cancelableBag))

            cancelableBag.add(cancelable: WeakCancelable(task))

            task.resume()

            return cancelableBag
        }

        private func handleHTTPResponse<R>(with completion: @escaping Network.CompletionClosure<R.Remote>,
                                           request: Request,
                                           resource: R,
                                           cancelableBag: CancelableBag)
        -> URLSessionDataTaskClosure
        where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response {

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
                    completion(.failure(Network.Error(type: .badResponse, response: nil)))
                    return
                }

                let httpStatusCode = HTTP.StatusCode(httpResponse.statusCode)
                var networkError: Error?

                switch (httpStatusCode, data) {
                case (.success, let remoteData?):
                    completion(.success(Network.Value(value: remoteData, response: httpResponse)))
                    return
                case (.success(204), nil) where R.Local.self == Void.self:
                    completion(.success(Network.Value(value: R.empty, response: httpResponse)))
                    return
                case (.success, _):
                    networkError = Network.Error(type: .noData, response: httpResponse)
                case let (statusCode, remoteData?):
                    let errorType = Network.Error.ErrorType.http(code: statusCode,
                                                                 apiError: resource.errorParser(remoteData))
                    networkError = Network.Error(type: errorType, response: httpResponse)
                case (let statusCode, _):
                    networkError = Network.Error(type: .http(code: statusCode, apiError: nil), response: httpResponse)
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

        private func authenticatedFetch<R>(using authenticator: NetworkAuthenticator,
                                           resource: R,
                                           completion: @escaping Network.CompletionClosure<R.Remote>) -> Cancelable
        where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response {

            let request = resource.request

            return authenticator.authenticate(request: request) { [weak self] result -> Cancelable in

                guard let strongSelf = self else { return DummyCancelable() }

                switch result {
                case let .success(authenticatedRequest):
                    return strongSelf.perform(request: authenticatedRequest, resource: resource, completion: completion)

                case let .failure(error):
                    completion(.failure(Network.Error(type: .authenticator(error.error), response: nil)))
                    return DummyCancelable()
                }
            }
        }

        // swiftlint:disable:next function_body_length function_parameter_count
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
                completion(.failure(Network.Error(type: .url(error), response: response)))
            case (.retry, _):
                guard cancelableBag.isCancelled == false else {
                    let error = Network.Error.ErrorType.retry(errors: resource.retryErrors,
                                                              totalDelay: resource.totalRetriedDelay,
                                                              retryError: .cancelled)
                    completion(.failure(Network.Error(type: error, response: response)))
                    return
                }

                cancelableBag += fetch(resource: resource, completion: completion)
            case (.retryAfter(let delay), _) where delay > 0:
                guard cancelableBag.isCancelled == false else {
                    let error = Network.Error.ErrorType.retry(errors: resource.retryErrors,
                                                              totalDelay: resource.totalRetriedDelay,
                                                              retryError: .cancelled)
                    completion(.failure(Network.Error(type: error, response: response)))
                    return
                }

                resource.totalRetriedDelay += delay

                let fetchWorkItem = DispatchWorkItem { [weak self] in
                    guard cancelableBag.isCancelled == false else {
                        let error = Network.Error.ErrorType.retry(errors: resource.retryErrors,
                                                                  totalDelay: resource.totalRetriedDelay,
                                                                  retryError: .cancelled)
                        completion(.failure(Network.Error(type: error, response: response)))
                        return
                    }

                    cancelableBag += self?.fetch(resource: resource, completion: completion)
                }

                cancelableBag += WeakCancelable(fetchWorkItem)

                retryQueue.asyncAfter(deadline: .now() + delay, execute: fetchWorkItem)
            case (.retryAfter, _): // retry delay is <= 0
                guard cancelableBag.isCancelled == false else {
                    let error = Network.Error.ErrorType.retry(errors: resource.retryErrors,
                                                              totalDelay: resource.totalRetriedDelay,
                                                              retryError: .cancelled)
                    completion(.failure(Network.Error(type: error, response: response)))
                    return
                }

                cancelableBag += fetch(resource: resource, completion: completion)
            case (.noRetry(let retryError), _):
                let error = Network.Error.ErrorType.retry(errors: resource.retryErrors,
                                                          totalDelay: resource.totalRetriedDelay,
                                                          retryError: retryError)
                completion(.failure(Network.Error.init(type: error, response: response)))
            }

        }
    }
}

extension Network.URLSessionNetworkStack: NetworkStore {
    public typealias E = NetworkPersistableStoreError
}
