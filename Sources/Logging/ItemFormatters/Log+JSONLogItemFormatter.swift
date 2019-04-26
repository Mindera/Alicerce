import Foundation

public extension Log {

    /// A log item formatter that outputs formatted items as JSON data.
    struct JSONLogItemFormatter: LogItemFormatter {

        /// The formatter's JSON encoder.
        private let encoder: JSONEncoder

        /// Creates an instance with the given encoder.
        ///
        /// - Parameter encoder: The encoder to format the items with.
        init(encoder: JSONEncoder = JSONEncoder()) {
            self.encoder = encoder
        }

        /// Formats a log item into a binary encoded JSON.
        ///
        /// - Parameter item: The log item to format.
        /// - Returns: A binary encoded JSON representing the formatted log item.
        /// - Throws: An error if the JSON encoding fails.
        public func format(item: Item) throws -> Data {
            return try encoder.encode(item)
        }
    }
}
