import Foundation

/// A type that logs messages with multiple possible severity log levels.
public protocol Logger: AnyObject {

    /// Logs a message with the given level, alongside the file, function and line the log originated from.
    ///
    /// - Parameters:
    ///   - level: The severity level of the message.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func log(level: Log.Level,
             message: @autoclosure () -> String,
             file: StaticString,
             line: UInt,
             function: StaticString)
}

public extension Logger {

    /// Logs a `verbose` log level message alongside the file, function and line the log originated from.
    ///
    /// - Parameters:
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func verbose(_ message: @autoclosure () -> String,
                 file: StaticString = #file,
                 line: UInt = #line,
                 function: StaticString = #function) {

        log(level: .verbose, message: message(), file: file, line: line, function: function)
    }

    /// Logs a `debug` log level message alongside the file, function and line the log originated from.
    ///
    /// - Parameters:
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func debug(_ message: @autoclosure () -> String,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {

        log(level: .debug, message: message(), file: file, line: line, function: function)
    }

    /// Logs an `info` log level message alongside the file, function and line the log originated from.
    ///
    /// - Parameters:
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func info(_ message: @autoclosure () -> String,
              file: StaticString = #file,
              line: UInt = #line,
              function: StaticString = #function) {

        log(level: .info, message: message(), file: file, line: line, function: function)
    }

    /// Logs a `warning` log level message alongside the file, function and line the log originated from.
    ///
    /// - Parameters:
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func warning(_ message: @autoclosure () -> String,
                 file: StaticString = #file,
                 line: UInt = #line,
                 function: StaticString = #function) {

        log(level: .warning, message: message(), file: file, line: line, function: function)
    }

    /// Logs an `error` log level message alongside the file, function and line the log originated from.
    ///
    /// - Parameters:
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func error(_ message: @autoclosure () -> String,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {

        log(level: .error, message: message(), file: file, line: line, function: function)
    }
}

public extension Logger where Self: LogDestination {

    func log(level: Log.Level,
             message: @autoclosure () -> String,
             file: StaticString,
             line: UInt,
             function: StaticString) {

        let item = Log.Item(timestamp: Date(),
                            module: nil,
                            level: level,
                            message: message(),
                            thread: Thread.currentName,
                            queue: DispatchQueue.currentLabel,
                            file: String(describing: file),
                            line: line,
                            function: String(describing: function))

        write(item: item) { error in

            guard self !== Log.internalLogger else { return }

            Log.internalLogger.error("💥 '\(type(of: self))' failed to log item: \(item) with error: \(error)")
        }
    }
}
