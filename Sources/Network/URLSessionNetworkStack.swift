import Foundation
import Result

public extension Network {

    final class URLSessionNetworkStack: NSObject, NetworkStack, URLSessionDelegate {

        public typealias Remote = Data
        public typealias Request = URLRequest
        public typealias Response = URLResponse

        public typealias URLSessionDataTaskClosure = (Data?, URLResponse?, Swift.Error?) -> Void

        private let authenticationChallengeHandler: AuthenticationChallengeHandler?
        private let requestInterceptors: [RequestInterceptor]
        private let retryQueue: DispatchQueue

        public var session: URLSession? {
            // In order to define `self` as the session's delegate while preserving dependency injection, the session 
            // must be injected via property. This is because the session's delegate is only defined on its `init`. 🤷‍♂️
            // The session's delegate could be set to `self` using a lazy var (since `self` is already defined), but 
            // then the session couldn't be injected for unit testing.

            willSet(session) {
                guard self.session == nil else {
                    fatalError("🔥 `self.session` must be `nil`!")
                }

                guard let session = session, session.delegate === self else {
                    fatalError("🔥 `session` must be non `nil` and \(self) must be its delegate!")
                }
            }
        }

        public init(authenticationChallengeHandler: AuthenticationChallengeHandler? = nil,
                    requestInterceptors: [RequestInterceptor] = [],
                    retryQueue: DispatchQueue) {

            self.authenticationChallengeHandler = authenticationChallengeHandler
            self.requestInterceptors = requestInterceptors
            self.retryQueue = retryQueue
        }

        public convenience init(configuration: Network.Configuration) {

            self.init(authenticationChallengeHandler: configuration.authenticationChallengeHandler,
                      requestInterceptors: configuration.requestInterceptors,
                      retryQueue: configuration.retryQueue)
        }

        /// Invalidates the stack's session, allowing any outstanding fetches to finish and breaking the session's
        /// reference to the stack (its delegate) as well as any callback objects.
        ///
        /// The session objects keep a strong reference to the delegate until the session is explicitly invalidated.
        /// If the stack's session isn't invalidated, the retain cycle is never broken and the app leaks (until it
        /// exits).
        ///
        /// - Important: This method should **always** be invoked before deinit'ing the stack, to avoid a retain cycle.
        ///
        /// - SeeAlso: `URLSession.finishTasksAndInvalidate`.
        public func finishFetchesAndInvalidateSession() {

            session?.finishTasksAndInvalidate()
        }

        @discardableResult
        public func fetch<R>(resource: R, completion: @escaping Network.CompletionClosure<R.External>) -> Cancelable
        where R: NetworkStack.FetchResource,
              R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

            return resource.makeRequest { [ weak self] result -> Cancelable in

                guard let strongSelf = self else { return DummyCancelable() }

                switch result {
                case let .success(request):
                    return strongSelf.perform(request: request, resource: resource, completion: completion)

                case let .failure(error):
                    completion(.failure(.noRequest(error.error)))
                    return DummyCancelable()
                }
            }
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
                                completion: @escaping Network.CompletionClosure<R.External>)
        -> Cancelable
        where R: NetworkStack.FetchResource,
              R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

            guard let session = session else {
                fatalError("🔥 `session` is `nil`! Forgot to 💉?")
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

        // swiftlint:disable:next function_body_length
        private func handleHTTPResponse<R>(with completion: @escaping Network.CompletionClosure<R.External>,
                                           request: Request,
                                           resource: R,
                                           cancelableBag: CancelableBag)
        -> URLSessionDataTaskClosure
        where R: NetworkStack.FetchResource,
              R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

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

                guard
                    let urlResponse = response,
                    let httpResponse = urlResponse as? HTTPURLResponse
                else {
                    // don't retry this error since this should "never" happen
                    completion(.failure(.badResponse(response)))
                    return
                }

                let httpStatusCode = HTTP.StatusCode(httpResponse.statusCode)
                var networkError: Error?

                switch (httpStatusCode, data) {
                case (.success, let remoteData?):
                    completion(.success(Value(value: remoteData, response: urlResponse)))
                    return
                case (.success(204...205), nil) where R.Internal.self == Void.self:
                    completion(.success(Value(value: R.empty, response: urlResponse)))
                    return
                case (.success, _):
                    networkError = .noData(urlResponse)
                case (let statusCode, let remoteData):
                    if let apiError = resource.decodeError(remoteData, urlResponse) {
                        networkError = .api(apiError, statusCode, urlResponse)
                    } else {
                        networkError = .http(statusCode, urlResponse)
                    }
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

        // swiftlint:disable:next function_body_length function_parameter_count
        private func handleError<R>(with completion: @escaping Network.CompletionClosure<R.External>,
                                    request: Request,
                                    error: Swift.Error,
                                    payload: Data?,
                                    response: Response?,
                                    resource: R,
                                    cancelableBag: CancelableBag)
        where R: NetworkStack.FetchResource,
              R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

            let metadata: R.RetryMetadata = (request: request, payload: payload, response: response)
            let action = resource.shouldRetry(with: error, metadata: metadata)

            var resource = resource
            resource.retryErrors.append(error)

            switch (action, error) {
            case (.none, let networkError as Error):
                completion(.failure(networkError))
            case (.none, _):
                completion(.failure(.url(error, response)))
            case (.retry, _):
                guard cancelableBag.isCancelled == false else {
                    completion(.failure(.retry(.cancelled,
                                               resource.retryErrors,
                                               resource.totalRetriedDelay,
                                               response)))
                    return
                }

                cancelableBag += fetch(resource: resource, completion: completion)
            case (.retryAfter(let delay), _) where delay > 0:
                guard cancelableBag.isCancelled == false else {
                    completion(.failure(.retry(.cancelled,
                                               resource.retryErrors,
                                               resource.totalRetriedDelay,
                                               response)))
                    return
                }

                resource.totalRetriedDelay += delay

                let fetchWorkItem = DispatchWorkItem { [weak self] in
                    guard cancelableBag.isCancelled == false else {
                        completion(.failure(.retry(.cancelled,
                                                   resource.retryErrors,
                                                   resource.totalRetriedDelay,
                                                   response)))
                        return
                    }

                    cancelableBag += self?.fetch(resource: resource, completion: completion)
                }

                cancelableBag += WeakCancelable(fetchWorkItem)

                retryQueue.asyncAfter(deadline: .now() + delay, execute: fetchWorkItem)
            case (.retryAfter, _): // retry delay is <= 0
                guard cancelableBag.isCancelled == false else {
                    completion(.failure(.retry(.cancelled,
                                               resource.retryErrors,
                                               resource.totalRetriedDelay,
                                               response)))
                    return
                }

                cancelableBag += fetch(resource: resource, completion: completion)
            case (.noRetry(let retryError), _):
                completion(.failure(.retry(retryError,
                                           resource.retryErrors,
                                           resource.totalRetriedDelay,
                                           response)))
            }

        }
    }
}

extension Network.URLSessionNetworkStack: NetworkStore {
    public typealias E = NetworkPersistableStoreError
}
