import Foundation

public extension Log {

    /// An error produced by a `ConsoleLogDestination`.
    enum ConsoleLogDestinationError: Error {

        /// Formatting a log item failed.
        case itemFormatFailed(Log.Item, Error)
    }

    /// A log destination that outputs log messages into the console, via an output closure.
    class ConsoleLogDestination<ItemFormatter: LogItemFormatter, MetadataKey: Hashable>: MetadataLogDestination
    where ItemFormatter.Output == String {

        /// A console destination's output closure, which invokes the console printing system call.
        public typealias OutputClosure = ((Level, String) -> Void)

        /// A console destinations' log metadata closure, which converts received metadata into a log message that is
        /// forwared to the output closure.
        public typealias LogMetadataClosure = ([MetadataKey : Any]) -> (Level, String)

        /// The destination's log item formatter.
        public let formatter: ItemFormatter

        /// The destination's minimum severity log level.
        public let minLevel: Level

        /// The destination's output closure. Should be used to wrap a call to `print`, `NSLog`, `os_log`, etc.
        /// - Note:
        /// Is invoked synchronously. This shouldn't be a problem or limitation if using one of the above system calls,
        /// since they're all thread safe.
        private let output: OutputClosure

        /// The destination's log metadata closure. When set, any time new metadata is set it will be converted into a
        /// message that is then forwarded into the `output` closure and logged. If `nil`, no metadata is logged.
        private let logMetadata: LogMetadataClosure?

        // MARK: - Lifecycle

        /// Creates a new instance of a log destination that outputs logs to the console.
        ///
        /// - Parameters:
        ///   - formatter: The log item formatter.
        ///   - minLevel: The minimum severity log level. Any item with a level below this level won't be logged. The
        /// default is `.error`.
        ///   - output: The output closure, which should be used to wrap the system call that will output to the console
        /// (e.g. `print`, `NSLog`, `os_log`, etc.). The default is `print(message)`.
        ///   - logMetadata: The metadata logging closure. If non `nil`, any time new metadata is set it will be
        /// converted into a message that is then forwarded into the `output` closure and logged. Otherwise, no metadata
        /// is logged. The default is `nil` (no metadata logging).
        public init(formatter: ItemFormatter,
                    minLevel: Level = .error,
                    output: @escaping OutputClosure = { level, message in print(message) },
                    logMetadata: LogMetadataClosure? = nil) {

            self.minLevel = minLevel
            self.formatter = formatter
            self.output = output
            self.logMetadata = logMetadata
        }

        // MARK: - Public methods

        /// Writes a log item to the console output, after being successfully formatted by the item formatter.
        ///
        /// - Parameters:
        ///   - item: The item to write.
        ///   - onFailure: The closure to be invoked on failure (if the formatter fails).
        public func write(item: Log.Item, onFailure: @escaping (Error) -> Void) {

            let formattedLogItem: String
            do {
                formattedLogItem = try formatter.format(item: item)
            } catch {
                return onFailure(ConsoleLogDestinationError.itemFormatFailed(item, error))
            }

            guard !formattedLogItem.isEmpty else { return }

            output(item.level, formattedLogItem)
        }

        /// Sets custom metadata by logging it to the console if `logMetadata` is **non nil**, to enrich existing log
        /// data (e.g. user info, device info, correlation ids, etc).
        ///
        /// This extra information can be very handy on its own, can and also be used to correlate logs between logging
        /// providers, for instance.
        ///
        /// - Parameters:
        ///   - metadata: The custom metadata to set.
        ///   - onFailure: The closure to be invoked on failure.
        public func setMetadata(_ metadata: [MetadataKey : Any], onFailure: @escaping (Error) -> Void) {

            guard let (level, message) = logMetadata?(metadata), !message.isEmpty else { return }

            output(level, message)
        }

        /// This method has an empty implementation because metadata is logged to console, and thus can't be removed
        /// after being logged to the console.
        ///
        /// - Parameters:
        ///   - keys: The custom metadata keys to remove.
        ///   - onFailure: The closure to be invoked on failure.
        public func removeMetadata(forKeys keys: [MetadataKey], onFailure: @escaping (Error) -> Void) {}
    }
}

extension Log.ConsoleLogDestination: Logger {}

extension Log.ConsoleLogDestination: MetadataLogger {}
