import Foundation

extension Log.ItemFormat {

    /// A component that formats and outputs the item's `timestamp`.
    public struct Timestamp: LogItemFormatComponent {

        public let formatting: Formatting<String>

        /// Instantiates a component that formats and outputs the log item's `timestamp` using the given date formatting
        /// closure.
        ///
        /// - Parameter format: The date formatting closure.
        @inlinable
        public init(format: @escaping (Date) -> String = ISO8601DateFormatter().string(from:)) {

            self.formatting = .init { $1 += format($0.timestamp) }
        }

        /// Instantiates a component that formats and outputs the log item's `timestamp` using the given date formatter.
        ///
        /// - Parameter dateFormatter: The date formatter.
        @inlinable
        public init(dateFormatter: DateFormatter) { self.init(format: dateFormatter.string(from:)) }
    }

    /// A component that outputs the item's `module` and falls back to a `default` string when `nil`.
    public struct Module: LogItemFormatComponent {

        public let formatting: Formatting<String>

        /// Instantiates a component that outputs the log item's `module`, falling back to a `default` string if the
        /// module is `nil`.
        ///
        /// - Parameter `default`: The fallback string.
        @inlinable
        public init(`default`: String = "") { self.formatting = .init { $1 += $0.module ?? `default` } }
    }

    /// A component that outputs the log item's `level` as its string representation.
    public struct Level: LogItemFormatComponent {

        public let formatting: Formatting<String> = .init { $1 += String(describing: $0.level) }

        @inlinable
        public init() {}
    }

    /// A component that outputs the log item's `level` as an emoji, with the following mapping:
    /// - `.verbose`: `"📓"`
    /// - `.debug`: `"📗"`
    /// - `.info`: `"📘"`
    /// - `.warning`: `"📒"`
    /// - `.error`: `"📕"`
    public struct EmojiLevel: LogItemFormatComponent {

        public let formatting: Formatting<String> = .init {
            switch $0.level {
            case .verbose:
                $1 += "📓"
            case .debug:
                $1 += "📗"
            case .info:
                $1 += "📘"
            case .warning:
                $1 += "📒"
            case .error:
                $1 += "📕"
            }
        }

        @inlinable
        public init() {}
    }

    /// A component that outputs the log item's `message`.
    public struct Message: LogItemFormatComponent {

        public let formatting: Formatting = .keyPath(\.message)

        @inlinable
        public init() {}
    }

    /// A component that outputs the log item's `thread`.
    public struct Thread: LogItemFormatComponent {

        public let formatting: Formatting = .keyPath(\.thread)

        @inlinable
        public init() {}
    }

    /// A component that outputs the log item's `queue`.
    public struct Queue: LogItemFormatComponent {

        public let formatting: Formatting = .keyPath(\.queue)

        @inlinable
        public init() {}
    }

    /// A component that formats and outputs the log item's `file`.
    public struct File: LogItemFormatComponent {

        public let formatting: Log.ItemFormat.Formatting<String>

        /// Instantiates a component that formats and outputs the log item's `file` by extracting the last path
        /// component, with or without extension depending on the given `includeExtension` flag.
        ///
        /// - Parameter includeExtension: The flag to determine whether to include extension or not.
        @inlinable
        public init(includeExtension: Bool = true) {

            self.formatting = .init {
                var url = URL(fileURLWithPath: $0.file)
                if !includeExtension { url.deletePathExtension() }
                $1 += url.lastPathComponent
            }
        }
    }

    /// A component that outputs the log item's `line` as its string representation.
    public struct Line: LogItemFormatComponent {

        public let formatting: Log.ItemFormat.Formatting<String> = .init { $1 += String($0.line) }

        @inlinable
        public init() {}
    }

    /// A component that outputs the log item's `function`.
    public struct Function: LogItemFormatComponent {

        public let formatting: Formatting = .keyPath(\.function)

        @inlinable
        public init() {}
    }
}

// MARK: Bash

extension Log.ItemFormat {

    public enum Bash {

        /// A component that outputs the bash color escape sequence string.
        public struct ColorEscape: LogItemFormatComponent {

            public let formatting: Formatting = .value("\u{001b}[38;5;")

            @inlinable
            public init() {}
        }

        /// A component that outputs the bash color reset sequence string.
        public struct ColorReset: LogItemFormatComponent {

            public let formatting: Formatting = .value("\u{001b}[0m")

            @inlinable
            public init() {}
        }

        /// A component that outputs the log item's `level` as a bash color code, with the following mapping:
        /// - `.verbose`: `"215m"`
        /// - `.debug`: `"35m"`
        /// - `.info`: `"39m"`
        /// - `.warning`: `"178m"`
        /// - `.error`: `"197m"`
        public struct ColorLevel: LogItemFormatComponent {

            public let formatting: Formatting<String> = .init {
                switch $0.level {
                case .verbose:
                    $1 += "251m"
                case .debug:
                    $1 += "35m"
                case .info:
                    $1 += "38m"
                case .warning:
                    $1 += "178m"
                case .error:
                    $1 += "197m"
                }
            }

            @inlinable
            public init() {}
        }

        /// A component that groups multiple components between bash color escape (`colorEscape`) and reset
        /// (`colorReset`), colored with the item's bash level color (`colorLevel`). An optional separator can be
        /// provided to be added between all elements of the group.
        public struct ColorGroup: LogItemFormatComponent {

            public let formatting: Formatting<String>

            /// Instantiates a component that groups an array of witnesses given via a result builder and wraps the
            /// output between bash color escape (`colorEscape`) and reset (`colorReset`), colored with the item's bash
            /// level color (`colorLevel`). An optional separator can be provided to be added between all elements of
            /// the group.
            ///
            /// - Parameters:
            ///   - separator: The separator string.
            ///   - builder: The formatting witness group array result builder.
            @inlinable
            public init(separator: String? = nil, @Log.ItemFormat.Builder builder: () -> [Formatting<String>]) {

                let separator = separator.map(Formatting.value) ?? .empty

                let formats = builder()
                let body = formats.dropLast().reduce(into: .empty) { $0 += $1 + separator } + (formats.last ?? .empty)

                self.formatting = ColorEscape().formatting + ColorLevel().formatting + body + ColorReset().formatting
            }
        }
    }
}
