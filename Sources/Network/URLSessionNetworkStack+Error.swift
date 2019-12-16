import Foundation

extension Network.URLSessionNetworkStack.Error {

    var response: URLResponse? {

        switch self {
        case .noRequest:
            return nil

        case .http(_, _, let response),
             .noData(let response):
            return response

        case .url(_, let response),
             .badResponse(let response),
             .retry(_, _, _, let response):
            return response
        }
    }

    var lastError: Network.URLSessionNetworkStack.Error {

        switch self {
        case .noRequest,
             .http,
             .noData,
             .url,
             .badResponse:
            return self

        case .retry(_, let errors, _, _):
            return errors.last as? Network.URLSessionNetworkStack.Error ?? self
        }
    }

    var statusCode: HTTP.StatusCode? {

        switch self {
        case .http(let statusCode, _, _):
            return statusCode

        case .noRequest,
             .noData,
             .url,
             .badResponse:
            return nil

        case .retry(_, let errors, _, _):
            if let lastError = errors.last as? Network.URLSessionNetworkStack.Error {
                return lastError.statusCode
            } else {
                return nil
            }
        }
    }
}
