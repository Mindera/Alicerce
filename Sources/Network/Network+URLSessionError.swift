import Foundation

#if canImport(AlicerceCore)
import AlicerceCore
#endif

extension Network {

    public enum URLSessionError: Error {

        public typealias APIError = Error
        public typealias TotalRetriedDelay = Retry.Delay

        case noRequest(Error)
        case http(HTTP.StatusCode, APIError?, URLResponse)
        case noData(HTTP.StatusCode, URLResponse)
        case url(URLError)
        case badResponse(URLResponse?)
        case retry(Retry.Error, Retry.State)
        case cancelled
    }
}

extension Network.URLSessionError {

    public var response: URLResponse? {

        switch self {
        case .noRequest,
             .url,
             .cancelled:
            return nil

        case .http(_, _, let response),
             .noData(_, let response):
            return response

        case .badResponse(let response):
            return response

        case .retry(_, let state):
            return (state.errors.last as? Network.URLSessionError)?.response
        }
    }

    public var lastError: Network.URLSessionError {

        switch self {
        case .noRequest,
             .http,
             .noData,
             .url,
             .badResponse,
             .cancelled:
            return self

        case .retry(_, let state):
            return state.errors.last as? Network.URLSessionError ?? self
        }
    }

    public var statusCode: HTTP.StatusCode? {

        switch self {
        case .http(let statusCode, _, _),
             .noData(let statusCode, _):
            return statusCode

        case .noRequest,
             .url,
             .badResponse,
             .cancelled:
            return nil

        case .retry(_, let state):
            return (state.errors.last as? Network.URLSessionError)?.statusCode
        }
    }
}
