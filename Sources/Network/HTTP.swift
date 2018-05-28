import Foundation


/// An enum containing HTTP related types.
public enum HTTP {

    public typealias Headers = [String : String]
    public typealias Query = [String : String]

    /// An enum describing the HTTP methods.
    public enum Method: String {
        case GET
        case HEAD
        case POST
        case PUT
        case PATCH
        case DELETE
        case TRACE
        case OPTIONS
    }

    /// An enum representing HTTP status codes, grouped by response class.
    ///
    /// - note: Based on https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
    public enum StatusCode: RawRepresentable {

        /// 1xx Informational
        case informational(Int)
        /// 2xx Success
        case success(Int)
        /// 3xx Redirection
        case redirection(Int)
        /// 4xx Client Error
        case clientError(Int)
        /// 5xx Server Error
        case serverError(Int)
        /// Unknown class error
        case unknownError(Int)

        /// The associated status code value.
        public var rawValue: Int {
            switch self {
            case let .informational(statusCode): return statusCode
            case let .success(statusCode): return statusCode
            case let .redirection(statusCode): return statusCode
            case let .clientError(statusCode): return statusCode
            case let .serverError(statusCode): return statusCode
            case let .unknownError(statusCode): return statusCode
            }
        }

        /// Instantiate a new `StatusCode` with the given code and infer the response class automatically.
        ///
        /// - parameter rawValue: the response's HTTP status code
        ///
        /// - returns: a newly instantiated `StatusCode` with the inferred class and associated status code.
        public init?(rawValue: Int) {
            self.init(rawValue)
        }

        /// Instantiate a new `StatusCode` with the given code and infer the response class automatically.
        ///
        /// - parameter statusCode: the response's HTTP status code
        ///
        /// - returns: a newly instantiated `StatusCode` with the inferred class and associated status code.
        public init(_ statusCode: Int) {
            self = {
                switch statusCode {
                case 100...199: return .informational(statusCode)
                case 200...299: return .success(statusCode)
                case 200...399: return .redirection(statusCode)
                case 400...499: return .clientError(statusCode)
                case 500...599: return .serverError(statusCode)
                default: return .unknownError(statusCode)
                }
            }()
        }
    }
}
