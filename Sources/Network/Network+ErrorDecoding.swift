import Foundation

extension Network {

    /// A custom error decoding witness.
    public struct ErrorDecoding<Payload, Metadata> {

        /// The error decode closure, invoked when some operation fails in an attempt to extract a custom error
        /// (e.g. extract API specific error after a HTTP protocol error).
        public let decode: (Payload?, Metadata) -> Error?

        /// Instantiates a new error decoder, with the given decode closure.
        /// - Parameter decode: The error decode closure.
        public init(decode: @escaping (Payload?, Metadata) -> Error?) {

            self.decode = decode
        }
    }
}

extension Network.ErrorDecoding where Payload == Data {

    /// An error decoding witness for `Decodable` errors encoded in JSON.
    public static func json<E: Error & Decodable>(
        _ t: E.Type = E.self,
        decoder: JSONDecoder = .init()
    ) -> Self {

        .init { data, response in data.flatMap { try? decoder.decode(E.self, from: $0) } }
    }
}
