import Foundation

extension Log {

    /// A dummy implementation of a `Logger`, to use when you don't want to log anything but need to have a logger set.
    public final class DummyLogger: Logger {

        /// Flag indicating if the logger should evaluate message `@autoclosure`s. If enabled, it replicates a "real"
        /// logger, which can help identify possible issues in string building/interpolation. It also causes log message
        /// evaluation to be accounted for in test code coverage reports.
        public let evaluateMessageClosures: Bool

        /// Creates a new dummy logger instance, that can optionally evaluate message `@autoclosure`s
        /// - Parameter evaluateMessageClosures: Flag indicating whether message `@autoclosure`s should be evaluated.
        /// Defaults to `true`.
        public init(evaluateMessageClosures: Bool = true) {

            self.evaluateMessageClosures = evaluateMessageClosures
        }

        public func log(
            level: Log.Level,
            message: @autoclosure () -> String,
            file: StaticString,
            line: Int,
            function: StaticString
        ) {

            if evaluateMessageClosures {
                _ = message()
            }
        }
    }
}
