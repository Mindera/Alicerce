import Foundation

/// A type that logs messages with multiple possible severity levels, originating from configurable app modules (or
/// none).
public protocol Logger {

    /// A type that represents any logical subsystems (modules) of your app you wish to log messages from.
    /// Messages can be logged with or without a defined module. If defined, module filtering will be enabled for that
    /// particular message (i.e. only messages whose log level is above a registered module's minumum log level will be
    /// logged. Otherwise, no module filtering will be done.
    ///
    /// A placeholder type `Log.NoModule` has been made available to be used on `Logger` instances that don't want to
    /// use modules and want a module type that can't be instantiated.
    associatedtype Module: LogModule

    // MARK: - Logging

    /// Logs a message from the specified module (if non `nil`) with the given level, alongside the file, function and
    /// line the log originated from.
    ///
    /// - Note:
    /// If the `module` parameter is non `nil`, the message will only be logged if the module is registered in the
    /// logger, and the log message's level is *above* the module's registered minimum log level. On the other hand, if
    /// `module` is set to `nil`, no module filtering will be applied.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated. Set to `nil` for no module filtering.
    ///   - level: The severity level of the message.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func log(module: Module?,
             level: Log.Level,
             message: @autoclosure () -> String,
             file: StaticString,
             line: UInt,
             function: StaticString)

    // MARK: - Modules

    /// Registers a module in the logger with a minimum severity log level, taking it into account when filtering
    /// any new log messages (if logged with a non `nil` module).
    ///
    /// - Note:
    /// Module filtering works as follows:
    ///
    /// A log message having a non `nil` module parameter will only be logged _if the module is registered_ in the
    /// logger, and the log message's level is *above* the module's registered minimum log level. On the other hand,
    /// if `module` is set to `nil`, no module filtering is applied.
    ///
    /// - Parameters:
    ///   - module: The module to be registered.
    ///   - minLevel: The minimum severity level required to be logged by the module.
    func registerModule(_ module: Module, minLevel: Log.Level) throws

    /// Unregisters a module from the logger, taking it into account when filtering any new log messages (if logged
    /// with a non `nil` module)
    ///
    /// - SeeAlso: `registerModule(_:minLevel:)`
    ///
    /// - Parameter module: The module to be unregistered.
    func unregisterModule(_ module: Module) throws

    // MARK: - Metadata

    /// Sets custom metadata in the logger, to enrich logging data (e.g. user info, device info, correlation ids, etc).
    ///
    /// This extra information can be very handy on its own, can and also be used to correlate logs between logging
    /// providers, for instance.
    ///
    /// - Parameter metadata: The custom metadata to set.
    func setMetadata(_ metadata: [AnyHashable : Any])

    /// Removes custom metadata from the logger's destinations, when any previous information became outdated (e.g.
    /// user signed out).
    ///
    /// - SeeAlso: `setMetadata(_:)`
    ///
    /// - Parameter keys: The custom metadata keys to remove.
    func removeMetadata(forKeys keys: [AnyHashable])
}

public extension Logger {

    /// Logs a `verbose` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message will only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func verbose(_ module: Module,
                 _ message: @autoclosure () -> String,
                 file: StaticString = #file,
                 line: UInt = #line,
                 function: StaticString = #function) {

        log(module: module, level: .verbose, message: message, file: file,  line: line, function: function)
    }

    /// Logs a `debug` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message will only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func debug(_ module: Module,
               _ message: @autoclosure () -> String,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {

        log(module: module, level: .debug, message: message, file: file,  line: line, function: function)
    }

    /// Logs an `info` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message will only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func info(_ module: Module,
              _ message: @autoclosure () -> String,
              file: StaticString = #file,
              line: UInt = #line,
              function: StaticString = #function) {

        log(module: module, level: .info, message: message, file: file,  line: line, function: function)
    }

    /// Logs a `warning` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message will only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func warning(_ module: Module,
                 _ message: @autoclosure () -> String,
                 file: StaticString = #file,
                 line: UInt = #line,
                 function: StaticString = #function) {

        log(module: module, level: .warning, message: message, file: file,  line: line, function: function)
    }

    /// Logs an `error` log level message from the specified module, alongside the file, function and line the log
    /// originated from.
    ///
    /// - Note:
    /// The message will only be logged if the module is registered in the logger, and the log message's level is
    /// *above* the module's registered minimum log level.
    ///
    /// - Parameters:
    ///   - module: The module from which the message originated.
    ///   - message: The log message.
    ///   - file: The file from where the log was invoked.
    ///   - line: The line from where the log was invoked.
    ///   - function: The function from where the log was invoked.
    func error(_ module: Module,
               _ message: @autoclosure () -> String,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {

        log(module: module, level: .error, message: message, file: file,  line: line, function: function)
    }
}

public extension Logger {

    /// Logs a `verbose` log level message _without_ a specified module, alongside the file, function and line the log
    /// originated from.
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

        log(module: nil, level: .verbose, message: message, file: file,  line: line, function: function)
    }

    /// Logs a `debug` log level message _without_ a specified module, alongside the file, function and line the log
    /// originated from.
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

        log(module: nil, level: .debug, message: message, file: file,  line: line, function: function)
    }

    /// Logs an `info` log level message _without_ a specified module, alongside the file, function and line the log
    /// originated from.
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

        log(module: nil, level: .info, message: message, file: file,  line: line, function: function)
    }

    /// Logs a `warning` log level message _without_ a specified module, alongside the file, function and line the log
    /// originated from.
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

        log(module: nil, level: .warning, message: message, file: file,  line: line, function: function)
    }

    /// Logs an `error` log level message _without_ a specified module, alongside the file, function and line the log
    /// originated from.
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

        log(module: nil, level: .error, message: message, file: file,  line: line, function: function)
    }
}
