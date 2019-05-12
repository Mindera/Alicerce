import Foundation

public enum Network {

    // MARK: - Response value

    public struct Value<T, Response> {

        public let value: T
        public let response: Response

        public init(value: T, response: Response) {

            self.value = value
            self.response = response
        }
    }
}
