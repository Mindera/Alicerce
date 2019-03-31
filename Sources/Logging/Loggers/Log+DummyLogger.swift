import Foundation

extension Log {

    /// A dummy implementation of a `Logger`, to use when you don't want to log anything but need to have a logger set.
    public final class DummyLogger: Logger {

        public func log(level: Log.Level,
                        message: @autoclosure () -> String,
                        file: StaticString,
                        line: UInt,
                        function: StaticString) {}
    }
}
