import Foundation

#if canImport(AlicerceCore)
import AlicerceCore
#endif

/// A type that logs messages with multiple possible severity levels, originating from configurable app modules.
public protocol ModuleLogger: Logger {

    /// A type that represents any logical subsystems (modules) of your app you wish to log messages from.
    /// Messages can be logged with or without a defined module. If defined, module filtering will be enabled for that
    /// particular message (i.e. only messages whose log level is above a registered module's minumum log level will be
    /// logged. Otherwise, no module filtering will be done.
    associatedtype Module: LogModule

    // MARK: - Logging

    /// Logs a message from the specified module with the given level, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message should only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - level: The severity level of the message.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func log( // swiftlint:disable:this function_parameter_count
        module: Module,
        level: Log.Level,
        message: @autoclosure () -> String,
        file: StaticString,
        line: UInt,
        function: StaticString
    )
}

public extension ModuleLogger {

    /// Logs a `verbose` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message should only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func verbose(
        _ module: Module,
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {

        log(module: module, level: .verbose, message: message(), file: file, line: line, function: function)
    }

    /// Logs a `debug` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message should only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func debug(
        _ module: Module,
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {

        log(module: module, level: .debug, message: message(), file: file, line: line, function: function)
    }

    /// Logs an `info` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message should only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func info(
        _ module: Module,
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {

        log(module: module, level: .info, message: message(), file: file, line: line, function: function)
    }

    /// Logs a `warning` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message should only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func warning(
        _ module: Module,
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {

        log(module: module, level: .warning, message: message(), file: file, line: line, function: function)
    }

    /// Logs an `error` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message should only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func error(
        _ module: Module,
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {

        log(module: module, level: .error, message: message(), file: file, line: line, function: function)
    }
}

public extension ModuleLogger where Self: LogDestination {

    // swiftlint:disable:next function_parameter_count
    func log(
        module: Module,
        level: Log.Level,
        message: @autoclosure () -> String,
        file: StaticString,
        line: UInt,
        function: StaticString
    ) {

        let item = Log.Item(
            timestamp: Date(),
            module: module.rawValue,
            level: level,
            message: message(),
            thread: Thread.currentName,
            queue: DispatchQueue.currentLabel,
            file: String(describing: file),
            line: line,
            function: String(describing: function)
        )

        write(item: item) { error in

            guard self !== Log.internalLogger else { return }

            Log.internalLogger.error("💥 '\(type(of: self))' failed to log item: \(item) with error: \(error)")
        }
    }
}
