import Foundation

public extension Log {

    /// A log item formatter that outputs formatted items as strings.
    public struct StringLogItemFormatter: LogItemFormatter {

        /// The formatter's format.
        public let format: Format

        // MARK: - Lifecycle

        /// Creates an instance with the given format string, log level and date formatters.
        ///
        /// - Parameters:
        ///   - format: The formatter's format object.
        public init(format: Format = .default) {
            self.format = format
        }

        /// Formats a log item into a String representation.
        ///
        /// - Parameter item: The log item to format.
        /// - Returns: A string representing the formatted log item.
        public func format(item: Item) throws -> String {
            return format.formatters
                .map { $0(item) }
                .joined()
        }
    }
}

// MARK: - Format

extension Log.StringLogItemFormatter {

    public final class Format {

        // MARK: - Type Alias

        public typealias Formatter = (Log.Item) -> String

        // MARK: - Static

        public static var `default`: Format {
            return Format()
                .joined(" ") { $0
                    .timestamp("HH:mm:ss.SSS")
                    .emoji()
                    .level()
                    .module()
                    .wrapped(before: "[", after: "]") { $0
                        .thread()
                        .text(" / ")
                        .queue()
                    }
                }
                .text(" ")
                .file()
                .text(".")
                .function()
                .text(":")
                .line()
                .text(" - ")
                .message()
        }

        // MARK: - Properties

        let separator: String?
        fileprivate var formatters: [Formatter] = []

        // MARK: - Lifecycle

        public init(separator: String? = nil) {
            self.separator = separator
        }

        public convenience init(separator: String? = nil, builder: (Format) -> Void) {
            self.init(separator: separator)
            builder(self)
        }

        @discardableResult
        public func module() -> Format {
            add(Format.module)
            return self
        }

        @discardableResult
        public func timestamp(_ format: String = "HH:mm:ss.SSS") -> Format {
            add(Format.timestamp(format))
            return self
        }

        @discardableResult
        public func emoji() -> Format {
            add(Format.emoji)
            return self
        }

        @discardableResult
        public func level() -> Format {
            add(Format.level)
            return self
        }

        @discardableResult
        public func message() -> Format {
            add(Format.message)
            return self
        }

        @discardableResult
        public func file(withExtension: Bool = false) -> Format {
            add(Format.file(withExtension: withExtension))
            return self
        }

        @discardableResult
        public func function() -> Format {
            add(Format.function)
            return self
        }

        @discardableResult
        public func line() -> Format {
            add(Format.line)
            return self
        }

        @discardableResult
        public func thread() -> Format {
            add(Format.thread)
            return self
        }

        @discardableResult
        public func queue() -> Format {
            add(Format.queue)
            return self
        }

        @discardableResult
        public func text(_ text: String) -> Format {
            add(Format.text(text))
            return self
        }

        @discardableResult
        public func joined(_ separator: String? = nil, format: (Format) -> Void) -> Format {
            add(formatters(separator: separator, from: format))
            return self
        }

        @discardableResult
        public func custom(_ formatter: @escaping Formatter) -> Format {
            add(formatter)
            return self
        }

        @discardableResult
        public func wrapped(before: Formatter? = nil,
                            after: Formatter? = nil,
                            separator: String? = nil,
                            format: (Format) -> Void) -> Format {
            add(Format.wrapped(before: before, after: after, formatters: formatters(separator: separator, from: format)))
            return self
        }

        @discardableResult
        public func wrapped(before: @escaping @autoclosure () -> String,
                            after: @escaping @autoclosure () -> String,
                            format: (Format) -> Void) -> Format {
            return wrapped(before: { _ in before() },
                           after: { _ in after() },
                           format: format)
        }

        // MARK: - Helpers

        private func formatters(separator: String? = nil, from format: (Format) -> Void) -> [Formatter] {
            return Format(separator: separator, builder: format).formatters
        }

        private func add(_ formatter: @escaping Formatter) {
            addSeparatorIfNeeded()
            formatters.append(formatter)
        }

        private func add(_ formatters: [Formatter]) {
            addSeparatorIfNeeded()
            self.formatters.append(contentsOf: formatters)
        }

        private func addSeparatorIfNeeded() {
            guard let separator = separator, formatters.isEmpty == false else { return }
            formatters.append(Format.text(separator))
        }
    }
}

// MARK: - Formatters

private extension Log.StringLogItemFormatter.Format {

    static let module: Formatter = { $0.module ?? "" }

    static func timestamp(_ format: String) -> Formatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return { dateFormatter.string(from: $0.timestamp) }
    }

    static let emoji: Formatter = {
        switch $0.level {
        case .verbose:
            return "📓"
        case .debug:
            return "📗"
        case .info:
            return "📘"
        case .warning:
            return "📒"
        case .error:
            return "📕"
        }
    }

    static let level: Formatter = { String(describing: $0.level).uppercased() }

    static let message: Formatter = { $0.message }

    static func file(withExtension: Bool) -> Formatter {
        return {
            let name = $0.file.components(separatedBy: "/").last ?? ""
            guard withExtension == false else { return name }
            return name.components(separatedBy: ".").first ?? ""
        }
    }

    static let function: Formatter = { $0.function }

    static let line: Formatter = { String($0.line) }

    static let thread: Formatter = { $0.thread }

    static let queue: Formatter = { $0.queue }

    static func text(_ value: String) -> Formatter {
        return { _ in value }
    }

    static func wrapped(before: Formatter? = nil, after: Formatter? = nil, formatters: [Formatter]) -> [Formatter] {
        var formatters = formatters
        if let before = before { formatters.insert(before, at: 0) }
        if let after = after { formatters.append(after) }
        return formatters
    }
}
