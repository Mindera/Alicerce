import Foundation

public protocol URLSessionNetworkStackRepresentable: NetworkStack
where
    Resource == Network.URLSessionResource,
    Remote == Data,
    Response == URLResponse,
    FetchError == Network.URLSessionError
{} // swiftlint:disable:this opening_brace

extension Network {

    public final class URLSessionNetworkStack: NSObject, URLSessionDelegate, URLSessionNetworkStackRepresentable {

        public typealias Resource = URLSessionResource
        public typealias Remote = Data
        public typealias Response = URLResponse
        public typealias FetchError = URLSessionError

        public typealias URLSessionDataTaskClosure = (Data?, URLResponse?, Swift.Error?) -> Void

        private let authenticationChallengeHandler: AuthenticationChallengeHandler?
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

        public init(
            authenticationChallengeHandler: AuthenticationChallengeHandler? = nil,
            retryQueue: DispatchQueue
        ) {

            self.authenticationChallengeHandler = authenticationChallengeHandler
            self.retryQueue = retryQueue
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

        // MARK: - URLSessionNetworkStackRepresentable

        @discardableResult
        public func fetch(resource: Resource, completion: @escaping FetchCompletionClosure) -> Cancelable {

            return resource.makeRequest { [weak self] result in

                guard let self = self else { return DummyCancelable() }

                switch result {
                case .success(let request):
                    return self.fetch(request: request, from: resource, completion: completion)

                case .failure(let error):
                    completion(.failure(.noRequest(error)))
                    return DummyCancelable()
                }
            }
        }

        // MARK: - URLSessionDelegate Methods

        public func urlSession(
            _ session: URLSession,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {

            if let handler = authenticationChallengeHandler {
                return handler.handle(challenge, completionHandler: completionHandler)
            }

            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }

        // MARK: - Private Methods

        private func fetch(
            request: URLRequest,
            from resource: Resource,
            completion: @escaping FetchCompletionClosure
        ) -> Cancelable {

            guard let session = session else {
                fatalError("🔥 `session` is `nil`! Forgot to 💉?")
            }

            let taskIdentifierBox = VarBox<Int>(.max)
            let cancelableBag = CancelableBag()

            let completionHandler = makeTaskCompletionHandler(
                request: request,
                resource: resource,
                taskIdentifierBox: taskIdentifierBox,
                cancelableBag: cancelableBag,
                completion: completion
            )

            let task = session.dataTask(with: request, completionHandler: completionHandler)

            taskIdentifierBox.value = task.taskIdentifier
            cancelableBag.add(cancelable: WeakCancelable(task))

            resource.interceptScheduledTask(withIdentifier: task.taskIdentifier, request: request)

            task.resume()

            return cancelableBag
        }

        // swiftlint:disable:next function_body_length
        private func makeTaskCompletionHandler(
            request: URLRequest,
            resource: Resource,
            taskIdentifierBox: VarBox<Int>,
            cancelableBag: CancelableBag,
            completion: @escaping FetchCompletionClosure
        ) -> URLSessionDataTaskClosure {

            return { [weak self] data, response, error in
                guard let self = self else { return }

                let taskIdentifier = taskIdentifierBox.value

                // handle any session level error
                if let error = error {
                    self.handleFailedFetch(
                        taskIdentifier: taskIdentifier,
                        request: request,
                        resource: resource,
                        data: data,
                        response: response,
                        error: .url(error.urlError),
                        cancelableBag: cancelableBag,
                        completion: completion
                    )
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

                switch (httpStatusCode, data) {
                case (.success, let remoteData?):
                    self.handleSuccessfulFetch(
                        taskIdentifier: taskIdentifier,
                        request: request,
                        resource: resource,
                        data: remoteData,
                        response: urlResponse,
                        completion: completion
                    )

                case (.success(204...205), nil):
                    self.handleSuccessfulFetch(
                        taskIdentifier: taskIdentifier,
                        request: request,
                        resource: resource,
                        data: Data(),
                        response: urlResponse,
                        completion: completion
                    )

                case (.success, _):
                    self.handleFailedFetch(
                        taskIdentifier: taskIdentifier,
                        request: request,
                        resource: resource,
                        data: data,
                        response: response,
                        error: .noData(urlResponse),
                        cancelableBag: cancelableBag,
                        completion: completion
                    )

                case (let statusCode, let remoteData):
                    let apiError = resource.errorDecoding.decode(remoteData, urlResponse)

                    self.handleFailedFetch(
                        taskIdentifier: taskIdentifier,
                        request: request,
                        resource: resource,
                        data: data,
                        response: response,
                        error: .http(statusCode, apiError, urlResponse),
                        cancelableBag: cancelableBag,
                        completion: completion
                    )
                }
            }
        }

        // swiftlint:disable:next function_parameter_count
        private func handleSuccessfulFetch(
            taskIdentifier: Int,
            request: URLRequest,
            resource: Resource,
            data: Data,
            response: URLResponse,
            completion: @escaping FetchCompletionClosure
        ) {

            resource.interceptSuccessfulTask(
                withIdentifier: taskIdentifier,
                request: request,
                data: data,
                response: response
            )

            completion(.success(.init(value: data, response: response)))
        }

        // swiftlint:disable:next function_parameter_count
        private func handleFailedFetch(
            taskIdentifier: Int,
            request: URLRequest,
            resource: Resource,
            data: Data?,
            response: URLResponse?,
            error: URLSessionError,
            cancelableBag: CancelableBag,
            completion: @escaping FetchCompletionClosure
        ) {

            let action = resource.interceptFailedTask(
                withIdentifier: taskIdentifier,
                request: request,
                data: data,
                response: response,
                error: error
            )

            var resource = resource
            resource.retryState.errors.append(error)

            switch action {
            case .none:
                completion(.failure(error))

            case .retry:
                guard cancelableBag.isCancelled == false else {
                    completion(.failure(.cancelled))
                    return
                }

                cancelableBag += fetch(resource: resource, completion: completion)

            case .retryAfter(let delay):
                guard cancelableBag.isCancelled == false else {
                    completion(.failure(.cancelled))
                    return
                }

                guard delay > 0 else {
                    cancelableBag += fetch(resource: resource, completion: completion)
                    return
                }

                resource.retryState.totalDelay += delay

                let fetchWorkItem = DispatchWorkItem { [weak self] in
                    cancelableBag += self?.fetch(resource: resource, completion: completion)
                }

                cancelableBag += fetchWorkItem

                retryQueue.asyncAfter(deadline: .now() + delay, execute: fetchWorkItem)

            case .noRetry(let retryError):
                completion(.failure(.retry(retryError, resource.retryState)))
            }
        }
    }
}

private extension Error {

    var urlError: URLError {

        // this should succeed, as apparently it's the correct error type
        // https://developer.apple.com/documentation/foundation/urlsession/datataskpublisher/failure
        if let urlError = self as? URLError {
            return urlError
        } else {
            let nsError = self as NSError
            return URLError(URLError.Code(rawValue: nsError.code), userInfo: nsError.userInfo)
        }
    }
}
