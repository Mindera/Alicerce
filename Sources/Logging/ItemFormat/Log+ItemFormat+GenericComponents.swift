import Foundation

extension Log {

    /// The namespace for all item format components.
    public enum ItemFormat {}
}

// MARK: - Value

extension Log.ItemFormat {

    /// A component that outputs a static value.
    public struct Value<Output>: LogItemFormatComponent {

        public let formatting: Formatting<Output>

        /// Instantiates a component that outputs a static value.
        ///
        /// - Parameters:
        ///   - value: The value to output.
        ///   - append: The output appending closure.
        @inlinable
        public init(_ value: Output, _ append: @escaping (inout Output, Output) -> Void) {

            self.formatting = .init { append(&$1, value) }
        }
    }
}

extension Log.ItemFormat.Value where Output: RangeReplaceableCollection {

    /// Instantiates a component that outputs a static value.
    ///
    /// - Parameters:
    ///   - value: The value to output.
    @inlinable
    public init(_ value: Output) { self.init(value, +=) }
}

// MARK: - Property

extension Log.ItemFormat {

    /// A component that outputs an item's property via a key path.
    public struct Property<Output>: LogItemFormatComponent {

        public let formatting: Formatting<Output>

        /// Instantiates a component that outputs an item's property of type `Output` via a key path.
        ///
        /// - Parameters:
        ///   - kp: The key path.
        ///   - append: The output appending closure.
        @inlinable
        public init(_ kp: KeyPath<Log.Item, Output>, _ append: @escaping (inout Output, Output) -> Void) {

            self.formatting = .init { append(&$1, $0[keyPath: kp]) }
        }

        /// Instantiates a component that outputs an item's optional property of type `Output` via a key path, falling
        /// back to a default value if `nil`.
        ///
        /// - Parameters:
        ///   - kp: The key path.
        ///   - append: The output appending closure.
        ///   - default: The default value.
        @inlinable
        public init(
            _ kp: KeyPath<Log.Item, Output?>,
            _ append: @escaping (inout Output, Output) -> Void,
            `default`: Output
        ) {

            self.formatting = .init { append(&$1, $0[keyPath: kp] ?? `default`) }
        }

        /// Instantiates a component that outputs an item's property of type `T` via a key path and applies a
        /// transformation to type `Output` via a closure.
        ///
        /// - Parameters:
        ///   - kp: The key path.
        ///   - append: The output appending closure.
        ///   - transform: The transform closure.
        @inlinable
        public init<T>(
            _ kp: KeyPath<Log.Item, T>,
            _ append: @escaping (inout Output, Output) -> Void,
            _ transform: @escaping (T) throws -> Output
        ) {

            self.formatting = .init { try append(&$1, transform($0[keyPath: kp])) }
        }

        /// Instantiates a component that outputs an item's optional property of type `T` via a key path and applies a
        /// transformation to type `Output` via a closure if non `nil`, falling back to a default value if `nil`.
        ///
        /// - Parameters:
        ///   - kp: The key path.
        ///   - append: The output appending closure.
        ///   - default: The default value.
        ///   - transform: The transform closure.
        @inlinable
        public init<T>(
            _ kp: KeyPath<Log.Item, T?>,
            _ append: @escaping (inout Output, Output) -> Void,
            `default`: Output,
            _ transform: @escaping (T) throws -> Output
        ) {

            self.formatting = .init { try append(&$1, $0[keyPath: kp].map(transform) ?? `default`) }
        }
    }
}

extension Log.ItemFormat.Property where Output: RangeReplaceableCollection {

    /// Instantiates a component that outputs an item's property of type `Output` via a key path.
    ///
    /// - Parameters:
    ///   - kp: The key path.
    @inlinable
    public init(_ kp: KeyPath<Log.Item, Output>) { self.init(kp, +=) }

    /// Instantiates a component that outputs an item's optional property of type `Output` via a key path, falling
    /// back to a default value if `nil`.
    ///
    /// - Parameters:
    ///   - kp: The key path.
    ///   - default: The default value.
    @inlinable
    public init(_ kp: KeyPath<Log.Item, Output?>, `default`: Output) { self.init(kp, +=, default: `default`) }

    /// Instantiates a component that outputs an item's property of type `T` via a key path and applies a
    /// transformation to type `Output` via a closure.
    ///
    /// - Parameters:
    ///   - kp: The key path.
    ///   - transform: The transform closure.
    @inlinable
    public init<T>(_ kp: KeyPath<Log.Item, T>, _ transform: @escaping (T) throws -> Output) {

        self.init(kp, +=, transform)
    }

    /// Instantiates a component that outputs an item's optional property of type `T` via a key path and applies a
    /// transformation to type `Output` via a closure if non `nil`, falling back to a default value if `nil`.
    ///
    /// - Parameters:
    ///   - kp: The key path.
    ///   - default: The default value.
    ///   - transform: The transform closure.
    @inlinable
    public init<T>(_ kp: KeyPath<Log.Item, T?>, `default`: Output, _ transform: @escaping (T) throws -> Output) {

        self.init(kp, +=, default: `default`, transform)
    }
}

// MARK: - Group

extension Log.ItemFormat {

    /// A component that groups multiple formatting witnesses with optional prefix, suffix and separator.
    public struct Group<Output>: LogItemFormatComponent {

        public let formatting: Formatting<Output>

        /// Instantiates a component that groups an array of formatting witnesses given via a result builder, and
        /// optionally appends a prefix before all group witnesses and/or a suffix after all group witnesses and/or a
        /// separator between all witnesses.
        ///
        /// - Parameters:
        ///   - prefix: The prefix value.
        ///   - separator: The separator value.
        ///   - suffix: The suffix value.
        ///   - empty: The empty output value.
        ///   - append: The output appending closure.
        ///   - builder: The formatting witness group array result builder.
        @inlinable
        public init(
            prefix: Output? = nil,
            separator: Output? = nil,
            suffix: Output? = nil,
            empty: Output,
            append: @escaping (inout Output, Output) -> Void,
            @Log.ItemFormat.GroupBuilder builder: () -> [Formatting<Output>]
        ) {

            let prefix = prefix.map { Formatting.value($0, append) } ?? .empty
            let separator = separator.map { Formatting.value($0, append) } ?? .empty
            let suffix = suffix.map { Formatting.value($0, append) } ?? .empty

            let formats = builder()
            let body = formats.dropLast().reduce(into: .empty) { $0 += $1 + separator } + (formats.last ?? .empty)

            self.formatting = prefix + body + suffix
        }
    }
}

extension Log.ItemFormat.Group where Output == String {

    /// Instantiates a component that groups an array of formatting witnesses given via a result builder, and
    /// optionally appends a prefix before all group witnesses and/or a suffix after all group witnesses and/or a
    /// separator between all witnesses.
    ///
    /// - Parameters:
    ///   - prefix: The prefix value.
    ///   - separator: The separator value.
    ///   - suffix: The suffix value.
    ///   - builder: The formatting witness group array result builder.
    @inlinable
    public init(
        prefix: Output? = nil,
        separator: Output? = nil,
        suffix: Output? = nil,
        @Log.ItemFormat.GroupBuilder builder: () -> [Log.ItemFormat.Formatting<Output>]
    ) {

        self.init(prefix: prefix, separator: separator, suffix: suffix, empty: "", append: +=, builder: builder)
    }
}

extension LogItemFormatComponent where Output == String {

    /// Wraps the receiver's output between the given prefix and suffix strings.
    ///
    /// - Parameters:
    ///   - prefix: The prefix string.
    ///   - suffix: The suffix string.
    @inlinable
    public func wrapped(prefix: Output, suffix: Output) -> Log.ItemFormat.Group<Output> {

        .init(prefix: prefix, suffix: suffix, builder: { self })
    }
}

// MARK: - Map

extension Log.ItemFormat {

    /// A component that transforms another component's output via a transform closure.
    public struct Map<Upstream: LogItemFormatComponent>: LogItemFormatComponent {

        public let formatting: Formatting<Upstream.Output>

        /// Instantiates a component that transforms a given `upstream` component's output via a `transform` closure.
        ///
        /// - Parameters:
        ///   - upstream: The upstream component.
        ///   - transform: The transform closure.
        ///   - empty: The empty output value.
        ///   - append: The output appending closure.
        @inlinable
        public init(
            upstream: Upstream,
            transform: @escaping (inout Output) throws -> Void,
            empty: Output,
            append: @escaping (inout Output, Output) -> Void
        ) {

            formatting = .init {
                var output = empty

                try upstream.formatting($0, &output)
                try transform(&output)

                append(&$1, output)
            }
        }
    }
}

extension Log.ItemFormat.Map where Output: RangeReplaceableCollection {

    /// Instantiates a component that transforms a given `upstream` component's output via a `transform` closure.
    ///
    /// - Parameters:
    ///   - upstream: The upstream component.
    ///   - transform: The transform closure.
    ///   - empty: The empty output value.
    @inlinable
    public init(
        upstream: Upstream,
        transform: @escaping (inout Output) throws -> Void,
        empty: Output
    ) {

        self.init(upstream: upstream, transform: transform, empty: empty, append: +=)
    }
}

extension LogItemFormatComponent where Output: RangeReplaceableCollection {

    /// Maps the receiver's output by applying the given `transform` closure.
    /// - Parameter transform: The transformation closure.
    @inlinable
    public func map(_ transform: @escaping (inout Output) -> Void, empty: Output) -> Log.ItemFormat.Map<Self> {

        .init(upstream: self, transform: transform, empty: empty, append: +=)
    }
}

// MARK: String

extension Log.ItemFormat.Map where Output == String {

    /// Instantiates a component that transforms a given `upstream` component's output via a `transform` closure.
    ///
    /// - Parameters:
    ///   - upstream: The upstream component.
    ///   - transform: The transform closure.
    @inlinable
    public init(upstream: Upstream, transform: @escaping (inout Output) throws -> Void) {

        self.init(upstream: upstream, transform: transform, empty: "")
    }
}

extension LogItemFormatComponent where Output == String {

    /// Maps the receiver's output by applying the given `transform` closure.
    /// - Parameter transform: The transformation closure.
    @inlinable
    public func map(_ transform: @escaping (inout Output) -> Void) -> Log.ItemFormat.Map<Self> {

        .init(upstream: self, transform: transform, empty: "")
    }

    /// Converts the receiver's output to uppercase.
    @inlinable
    public func uppercased() -> Log.ItemFormat.Map<Self> { map { $0 = $0.uppercased() } }

    /// Converts the receiver's output to lowercase.
    @inlinable
    public func lowercased() -> Log.ItemFormat.Map<Self> { map { $0 = $0.lowercased() } }

    /// Left-pads the receiver's output with the specified character up to the given width.
    ///
    /// - Parameters:
    ///   - width: The width up to which the output should be left padded.
    ///   - character: The character to use when padding.
    @inlinable
    public func leftPadded(_ width: Int, character: Character = " ") -> Log.ItemFormat.Map<Self> {

        map { $0 = String(repeating: character, count: max(0, width - $0.count)) + $0 }
    }

    /// Right-pads the receiver's output with the specified character up to the given width.
    ///
    /// - Parameters:
    ///   - width: The width up to which the output should be right-padded.
    ///   - character: The character to use when padding.
    @inlinable
    public func rightPadded(_ width: Int, character: Character = " ") -> Log.ItemFormat.Map<Self> {

        map { $0 += String(repeating: character, count: max(0, width - $0.count)) }
    }

    /// Removes the characters defined in the given character set from both ends of the output.
    ///
    /// - Parameter characterSet: The character set.
    @inlinable
    public func trimmed(characterSet: CharacterSet = .whitespaces) -> Log.ItemFormat.Map<Self> {

        map { $0 = $0.trimmingCharacters(in: characterSet) }
    }
}

// MARK: Data

extension LogItemFormatComponent where Output == Data {

    /// Maps the receiver's output by applying the given `transform` closure.
    /// - Parameter transform: The transformation closure.
    @inlinable
    public func map(_ transform: @escaping (inout Output) -> Void) -> Log.ItemFormat.Map<Self> {

        .init(upstream: self, transform: transform, empty: .init())
    }
}
