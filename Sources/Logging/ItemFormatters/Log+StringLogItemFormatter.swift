public extension Log {

    /// A log item formatter that outputs formatted items as strings.
    struct StringLogItemFormatter: LogItemFormatter {

        /// The formatter's formatting witness.
        public let formatting: Log.ItemFormat.Formatting<Output>

        /// Creates an instance with the formatting witness built via the provided `@FormattingBuilder`.
        ///
        /// - Parameters:
        ///   - formatting: The formatting witness builder.
        public init(
            @Log.ItemFormat.Builder formatting: () -> Log.ItemFormat.Formatting<Output> = { Log.ItemFormat.string }
        ) {

            self.formatting = formatting()
        }

        /// Formats a log item into a String representation.
        ///
        /// - Parameter item: The log item to format.
        /// - Returns: A string representing the formatted log item.
        public func format(item: Item) throws -> String { try formatting.formatItem(item) }
    }
}
