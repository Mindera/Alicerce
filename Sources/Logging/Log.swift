import Foundation

/// A type representing the Log namespace (case-less enum).
public enum Log {

    /// A log item value that represents a log message and its context.
    public struct Item: Equatable, Codable {

        /// The timestamp when the log item was created.
        public let timestamp: Date

        /// The module of the log item.
        public let module: String?

        /// The severity level of the log item.
        public let level: Level

        /// The message of the log item.
        public let message: String

        /// The current thread's name when the log item was created.
        public let thread: String

        /// The current queue's label when the log item was created.
        public let queue: String

        /// The file from where the log originated.
        public let file: String

        /// The file line from where the log originated.
        public let line: UInt

        /// The function from where the log originated.
        public let function: String
    }

    /// A logging level defining message severity levels, as well as enabling filtering on a per log destination basis.
    public enum Level: Int, Codable {
        case verbose
        case debug
        case info
        case warning
        case error

        /// Checks if `self` is above the specified (minimum) log level. A message can be logged if its level is
        /// *greater than or equal* to another level defined as minimum.
        ///
        /// The relationship between levels is as follows:
        /// `.verbose` < `.debug` < `.info` < `.warning` < `.error`
        ///
        /// - Parameter minLevel: The level to compare against `self`.
        /// - Returns: `true` if `self` is above the given level, `false` otherwise.
        func isAbove(minLevel: Level) -> Bool {
            return minLevel.rawValue <= rawValue
        }
    }

    /// A queue object used to specify `DispatchQueue`'s used in log destinations, ensuring they are serial with the
    /// specified QoS, targeting an optional queue.
    public final class Queue {

        /// The inner GCD queue.
        public let dispatchQueue: DispatchQueue

        /// Creates an instance with the specified label, QoS and target queue.
        ///
        /// - Parameters:
        ///   - label: The inner dispatch queue's label.
        ///   - qos: The inner dispatch queue's quality of service.
        ///   - target: The inner dispatch queue's target queue.
        public init(label: String, qos: DispatchQoS = .utility, target: DispatchQueue? = nil) {
            dispatchQueue = DispatchQueue(label: label, qos: qos, target: target)
        }
    }
}

extension Log {

    /// The framework's (configurable) internal logger, mostly used as a default error logger, or to log errors which
    /// don't impact normal functioning and are not exposed/propagated via the current API's.
    ///
    /// The default value is set to a `Log.ConsoleLogDestination` instance configured with a `StringLogItemFormatter`
    /// with the format string: `"$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - [Alicerce 🏗] $M"`.
    ///
    /// Set to a `Log.DummyLogger` instance to disable logging from the framework, or to the `Logger` of your choice to
    /// easily include Alicerce's logs into to your own logs.
    ///
    /// - Warning: This variable is **not** thread safe (for performance reasons). If you wish to customize its value
    /// please do so just once on app launch, or before using any of Alicerce's components.
    public static var internalLogger: Logger = {

        let format = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - [Alicerce 🏗] $M"

        let formatter = Log.StringLogItemFormatter()
        let destination = Log.ConsoleLogDestination<StringLogItemFormatter, NoMetadataKey>(formatter: formatter)

        return destination
    }()
}
