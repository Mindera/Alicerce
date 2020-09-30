import Foundation

public enum Network {

    public struct Value<T, Response> {

        public let value: T
        public let response: Response

        public init(value: T, response: Response) {

            self.value = value
            self.response = response
        }
    }

    public typealias URLSessionRetryPolicy = Retry.Policy<(URLRequest, Data?, URLResponse?)>
}

extension Network.Value {

    public func mapValue<U>(_ f: (T, Response) throws -> U) rethrows -> Network.Value<U, Response> {

        .init(value: try f(value, response), response: response)
    }
}
