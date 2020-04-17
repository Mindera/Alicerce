import Foundation

extension Network {

    /// A custom model decoding witness.
    public struct ModelDecoding<T, Payload, Metadata> {

        /// The model decode closure, invoked to convert some payload and metadata into a model instance.
        public let decode: (Payload, Metadata) throws -> T
    }
}

extension Network.ModelDecoding where T: Decodable, Payload == Data {

    /// A model decoding witness for `Decodable` types encoded in JSON.
    public static func json(_ t: T.Type = T.self) -> Self {

        .init { data, _ in try JSONDecoder().decode(T.self, from: data) }
    }
}
