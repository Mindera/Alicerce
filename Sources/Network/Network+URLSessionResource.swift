import Foundation

extension Network {

    public struct URLSessionResource {

        public let baseRequestMaking: BaseRequestMaking<URLRequest>
        public let errorDecoding: ErrorDecoding<Data, URLResponse>

        public let interceptors: [URLSessionResourceInterceptor]

        public internal(set) var retryState: Retry.State
        public let retryActionPriority: Retry.Action.CompareClosure

        public init(
            baseRequestMaking: BaseRequestMaking<URLRequest>,
            errorDecoding: ErrorDecoding<Data, URLResponse>,
            interceptors: [URLSessionResourceInterceptor],
            retryActionPriority: @escaping Retry.Action.CompareClosure = Retry.Action.mostPrioritary
        ) {

            self.baseRequestMaking = baseRequestMaking
            self.errorDecoding = errorDecoding
            self.interceptors = interceptors
            self.retryState = .empty
            self.retryActionPriority = retryActionPriority
        }
    }
}

extension Network.URLSessionResource {

    typealias RequestHandler = (Result<URLRequest, Error>) -> Cancelable

    func makeRequest(handler: @escaping RequestHandler) -> Cancelable {

        baseRequestMaking.make { [interceptors] requestResult in

            var iterator = interceptors.makeIterator()

            guard let first = iterator.next() else { return handler(requestResult) }

            // chain interceptors recursively
            func makeHandler() -> RequestHandler {
                return { newResult -> Cancelable in
                    if let next = iterator.next() {
                        return next.interceptMakeRequestResult(newResult, handler: makeHandler())
                    }
                    return handler(newResult)
                }
            }

            return first.interceptMakeRequestResult(requestResult, handler: makeHandler())
        }
    }

    func interceptScheduledTask(withIdentifier taskIdentifier: Int, request: URLRequest) {

        interceptors.forEach {
            $0.interceptScheduledTask(withIdentifier: taskIdentifier, request: request, retryState: retryState)
        }
    }

    func interceptSuccessfulTask(
        withIdentifier taskIdentifier: Int,
        request: URLRequest,
        data: Data,
        response: URLResponse
    ) {

        interceptors.forEach {
            $0.interceptSuccessfulTask(
                withIdentifier: taskIdentifier,
                request: request,
                data: data,
                response: response,
                retryState: retryState
            )
        }
    }

    func interceptFailedTask(
        withIdentifier taskIdentifier: Int,
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Network.URLSessionError
    ) -> Retry.Action {

        interceptors
            .map {
                $0.interceptFailedTask(
                    withIdentifier: taskIdentifier,
                    request: request,
                    data: data,
                    response: response,
                    error: error,
                    retryState: retryState
                )
            }
            .reduce(Retry.Action.none, retryActionPriority)
    }
}
