import Alicerce

public extension Log {

    public class StringLogDestination: LogDestination {

        public let minLevel: Level
        public let formatter: LogItemFormatter
        public let logSeparator: String

        public private(set) var output = ""

        // MARK: - Lifecycle

        public init(minLevel: Level = Level.error,
                    formatter: LogItemFormatter = StringLogItemFormatter(),
                    logSeparator: String = "\n") {

            self.minLevel = minLevel
            self.formatter = formatter
            self.logSeparator = logSeparator
        }

        // MARK: - Public methods

        public func write(item: Item, failure: @escaping (Swift.Error) -> ()) {
            if !output.isEmpty {
                output += logSeparator
            }

            output += formatter.format(logItem: item)
        }
    }
}
