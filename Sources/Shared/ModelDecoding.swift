import Foundation

/// A custom model decoding witness.
public struct ModelDecoding<T, Payload, Metadata> {

    /// The model decode closure, invoked to convert some payload and metadata into a model instance.
    public let decode: (Payload, Metadata) throws -> T

    /// Instantiates a new model decoder, with the given decode closure.
    /// - Parameter decode: The model decode closure.
    public init(decode: @escaping (Payload, Metadata) throws -> T) {

        self.decode = decode
    }
}

extension ModelDecoding where T: Decodable, Payload == Data {

    /// A model decoding witness for `Decodable` types encoded in JSON.
    public static func json(_ t: T.Type = T.self, decoder: JSONDecoder = .init()) -> Self {

        .init { data, _ in try decoder.decode(T.self, from: data) }
    }
}
