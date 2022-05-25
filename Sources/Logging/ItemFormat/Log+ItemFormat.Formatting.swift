import Foundation

extension Log.ItemFormat {

    /// A log item formatting witness.
    public struct Formatting<Output> {

        /// The log item formatting closure.
        public var format: (Log.Item, inout Output) throws -> Void

        @inlinable
        public func callAsFunction(_ i: Log.Item, _ o: inout Output) throws { try format(i, &o) }

        /// Instantiates a new string log formatting witness, with the given formatting closure.
        /// - Parameter format: The log item formatting closure.
        @inlinable
        public init(format: @escaping (Log.Item, inout Output) throws -> Void) { self.format = format }

        /// Formats the given item into an output value from an empty output value.
        ///
        /// - Parameters:
        ///   - item: The item to format.
        ///   - empty: An empty output value.
        /// - Returns:  A formatted output value of the item.
        @inlinable
        public func formatItem(_ item: Log.Item, empty: Output) throws -> Output {

            var output = empty
            try self(item, &output)
            return output
        }
    }
}

extension Log.ItemFormat.Formatting where Output == String {

    /// Formats the given item into a string.
    /// - Parameter item: The item to format.
    /// - Returns: A formatted string of the item.
    @inlinable
    public func formatItem(_ item: Log.Item) throws -> Output { try formatItem(item, empty: "") }
}

extension Log.ItemFormat.Formatting where Output == Data {

    /// Formats the given item into a byte buffer.
    /// - Parameter item: The item to format.
    /// - Returns: A formatted byte buffer of the item.
    @inlinable
    public func formatItem(_ item: Log.Item) throws -> Output { try formatItem(item, empty: .init()) }
}

// MARK: - Operators

@inlinable
public func + <Output>(
    lhs: Log.ItemFormat.Formatting<Output>,
    rhs: Log.ItemFormat.Formatting<Output>
) -> Log.ItemFormat.Formatting<Output> {

    .init {
        try lhs($0, &$1)
        try rhs($0, &$1)
    }
}

@inlinable
public func += <Output>(lhs: inout Log.ItemFormat.Formatting<Output>, rhs: Log.ItemFormat.Formatting<Output>) {

    lhs.format = { [lhs = lhs.format] in
        try lhs($0, &$1)
        try rhs($0, &$1)
    }
}

// MARK: - Generic witnesses

extension Log.ItemFormat.Formatting {

    /// A formatting witness that does nothing.
    @inlinable
    public static var empty: Self { .init { _, _ in } }

    /// Creates a formatting witness that appends an item's property value via the given keypath and append function.
    ///
    /// - Parameters:
    ///   - kp: The keypath to the item's property.
    ///   - append: The append function.
    @inlinable
    public static func keyPath(
        _ kp: KeyPath<Log.Item, Output>,
        _ append: @escaping (inout Output, Output) -> Void
    ) -> Self {

        .init { append(&$1, $0[keyPath: kp]) }
    }

    /// Creates a formatting witness that appends a static value via the given append function.
    ///
    /// - Parameters:
    ///   - value: The value to output.
    ///   - append: The append function.
    @inlinable
    public static func value(_ value: Output, _ append: @escaping (inout Output, Output) -> Void) -> Self {

        .init { append(&$1, value) }
    }
}

// MARK: RangeReplaceableCollection

extension Log.ItemFormat.Formatting where Output: RangeReplaceableCollection {

    /// Creates a formatting witness that appends an item's property value via the given keypath.
    ///
    /// - Parameter kp: The keypath to the item's property.
    @inlinable
    public static func keyPath(_ kp: KeyPath<Log.Item, Output>) -> Self { .keyPath(kp, +=) }

    /// Creates a formatting witness that appends a static value.
    ///
    /// - Parameter value: The text to output.
    @inlinable
    public static func value(_ value: Output) -> Self { .value(value, +=) }
}

// MARK: - Default instances

extension Log.ItemFormat {

    /// The default string formatting witness, resulting in the log format:
    ///
    /// `"<ISO8601 date> <module>? | <level emoji> <level> | [<thread>/<queue>] <function> | <file>:<line> | <msg>"`
    @inlinable
    @Builder
    public static var string: Log.ItemFormat.Formatting<String> {
        Group(separator: " ") {
            Group(separator: " ") {
                Timestamp()
                Module()
            }
            .trimmed() // remove empty space if `nil` module
            "|"
            EmojiLevel()
            Level()
                .uppercased()
                .rightPadded(7) // pad with spaces up to max level name length
            "|"
            Group(prefix: "[", separator: "/", suffix: "]") {
                Thread()
                Queue()
            }
            Function()
            "|"
            Group(separator: ":") {
                File()
                Line()
            }
            "|"
            \.message
        }
    }
}
