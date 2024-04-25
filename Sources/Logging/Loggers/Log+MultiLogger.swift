import Foundation

#if canImport(AlicerceCore)
import AlicerceCore
#endif

extension Log {

    /// An implementation of a `LogModule` that can't be created, to allow using a `MultiLogger` without modules.
    public struct NoModule: LogModule {

        public init?(rawValue: String) { return nil }

        public let rawValue: String
    }

    /// An implementation of a `MetadataKey` that can't be created, to allow using a `MultiLogger` without metadata.
    public enum NoMetadataKey: Hashable {}

    /// A logger that forwards logging events to multiple log destinations, while not doing any logging on its own.
    public final class MultiLogger<Module: LogModule, MetadataKey: Hashable>: ModuleLogger, MetadataLogger {

        /// A logger's log destination error callback closure, invoked whenever any of its destinations fails an
        /// operation.
        public typealias LogDestinationErrorClosure = ((LogDestination, Error) -> Void)

        /// The logger's destinations. The destinations are stored as type erased versions to enable storing multiple
        /// `MetadataLogDestination`'s with the same `MetadataKey`.
        public let destinations: [AnyMetadataLogDestination<MetadataKey>]

        /// The logger's modules.
        public let modules: [Module: Log.Level]

        /// The logger's log destination error callback closure.
        private let onError: LogDestinationErrorClosure?

        /// Creates a new multi logger instance, with the specified log destinations and modules.
        ///
        /// - Note:
        /// Module filtering works as follows:
        ///
        /// A log message having a module parameter will only be logged _if the module is registered_ in the logger, and
        /// the log message's level is *above* the module's registered minimum log level. On the other hand, if the
        /// message is logged without module (i.e. using the `Logger`'s `log` API, i.e. *without* `module` parameter),
        /// no module filtering will be made.
        ///
        /// - Parameters:
        ///   - modules: The log modules and respective minimum log level to be registered. Used when the
        ///   `ModuleLogger` APIs are used (i.e. with `module` parameter).
        ///   - onError: The logger's log destination error callback closure.
        ///   - destinations: The result builder which outputs log destinations to forward logging events to.
        public init(
            modules: [Module: Log.Level] = [:],
            onError: LogDestinationErrorClosure? = nil,
            @DestinationBuilder destinations: () -> [AnyMetadataLogDestination<MetadataKey>]
        ) {

            self.modules = modules

            self.onError = onError ?? { destination, error in
                Log.internalLogger.error("💥 LogDestination '\(destination)' failed operation with error: \(error)")
            }

            self.destinations = destinations()

            assert(
                !self.destinations.isEmpty,
                "🙅‍♂️ Destinations shouldn't be empty, since it renders this logger useless!"
            )
        }

        /// Creates a new multi logger instance, with the specified log destinations and modules.
        ///
        /// - Note:
        /// Module filtering works as follows:
        ///
        /// A log message having a module parameter will only be logged _if the module is registered_ in the logger, and
        /// the log message's level is *above* the module's registered minimum log level. On the other hand, if the
        /// message is logged without module (i.e. using the `Logger`'s `log` API, i.e. *without* `module` parameter),
        /// no module filtering will be made.
        ///
        /// - Parameters:
        ///   - destinations: The log destinations to forward logging events to.
        ///   - modules: The log modules and respective minimum log level to be registered. Used when the
        ///   `ModuleLogger` APIs are used (i.e. with `module` parameter).
        ///   - onError: The logger's log destination error callback closure.
        public init(
            destinations: [AnyMetadataLogDestination<MetadataKey>],
            modules: [Module: Log.Level] = [:],
            onError: LogDestinationErrorClosure? = nil
        ) {

            assert(!destinations.isEmpty, "🙅‍♂️ Destinations shouldn't be empty, since it renders this logger useless!")

            self.destinations = destinations
            self.modules = modules

            self.onError = onError ?? { destination, error in
                Log.internalLogger.error("💥 LogDestination '\(destination)' failed operation with error: \(error)")
            }
        }

        // MARK: - Logging

        /// Logs a message from the specified module with the given level, alongside the file, function and line the
        /// log originated from.
        ///
        /// - Note:
        /// The message will only be logged if the module is registered in the logger, and the log message's level is
        /// *above* the module's registered minimum log level.
        ///
        /// - Parameters:
        ///   - module: The module from which the message originated.
        ///   - level: The severity level of the message.
        ///   - message: The log message.
        ///   - file: The file from where the log was invoked.
        ///   - line: The line from where the log was invoked.
        ///   - function: The function from where the log was invoked.
        public func log(
            module: Module,
            level: Log.Level,
            message: @autoclosure () -> String,
            file: StaticString = #file,
            line: Int = #line,
            function: StaticString = #function
        ) {

            _log(module: module, level: level, message: message(), file: file, line: line, function: function)
        }

        /// Logs a message from the specified module (if non `nil`) with the given level, alongside the file, function
        /// and line the log originated from.
        ///
        /// - Note:
        /// If the `module` parameter is non `nil`, the message will only be logged if the module is registered in the
        /// logger, and the log message's level is *above* the module's registered minimum log level. On the other hand,
        /// if `module` is set to `nil`, no module filtering will be applied.
        ///
        /// - Parameters:
        ///   - module: The module from which the message originated. Set to `nil` for no module filtering.
        ///   - level: The severity level of the message.
        ///   - message: The log message.
        ///   - file: The file from where the log was invoked.
        ///   - line: The line from where the log was invoked.
        ///   - function: The function from where the log was invoked.
        public func log(
            level: Log.Level,
            message: @autoclosure () -> String,
            file: StaticString = #file,
            line: Int = #line,
            function: StaticString = #function
        ) {

            _log(module: nil, level: level, message: message(), file: file, line: line, function: function)
        }

        /// Logs a message from the specified module (if non `nil`) with the given level, alongside the file, function
        /// and line the log originated from. Base implementation for both `Logger` and `ModuleLogger` `log` methods.
        ///
        /// - Note:
        /// If the `module` parameter is non `nil`, the message will only be logged if the module is registered in the
        /// logger, and the log message's level is *above* the module's registered minimum log level. On the other hand,
        /// if `module` is set to `nil`, no module filtering will be applied.
        ///
        /// - Parameters:
        ///   - module: The module from which the message originated. Set to `nil` for no module filtering.
        ///   - level: The severity level of the message.
        ///   - message: The log message.
        ///   - file: The file from where the log was invoked.
        ///   - line: The line from where the log was invoked.
        ///   - function: The function from where the log was invoked.
        private func _log(
            module: Module?,
            level: Level,
            message: @autoclosure () -> String,
            file: StaticString = #file,
            line: Int = #line,
            function: StaticString = #function
        ) {

            // skip module checks for `nil` modules
            if let module = module {
                guard let moduleMinLevel = modules[module], level.meets(minLevel: moduleMinLevel) else { return }
            }

            let matchingDestinations = destinations.filter { level.meets(minLevel: $0.minLevel) }

            guard matchingDestinations.isEmpty == false else { return }

            // only create the item if effectively needed (thus taking advantage of @autoclosure)
            let item = Item(
                timestamp: Date(),
                module: module?.rawValue,
                level: level,
                message: message(),
                thread: Thread.currentName,
                queue: DispatchQueue.currentLabel,
                file: String(describing: file),
                line: line,
                function: String(describing: function)
            )

            matchingDestinations.forEach {
                $0.write(item: item, onFailure: handleFailure(for: $0))
            }
        }

        // MARK: - Metadata

        /// Sets custom metadata in the logger's destinations, to enrich logging data (e.g. user info, device info,
        /// correlation ids, etc).
        ///
        /// This extra information can be very handy on its own, can and also be used to correlate logs between logging
        /// providers, for instance.
        ///
        /// - Parameter metadata: The custom metadata to set.
        public func setMetadata(_ metadata: [MetadataKey : Any]) {

            destinations.forEach { $0.setMetadata(metadata, onFailure: handleFailure(for: $0)) }
        }

        /// Removes custom metadata from the logger's destinations, when any previous information became outdated (e.g.
        /// user signed out).
        ///
        /// - SeeAlso: `setMetadata(_:)`
        ///
        /// - Parameter keys: The custom metadata keys to remove.
        public func removeMetadata(forKeys keys: [MetadataKey]) {

            destinations.forEach { $0.removeMetadata(forKeys: keys, onFailure: handleFailure(for: $0)) }
        }

        // MARK: - Auxiliary

        /// Creates a closure to handle a destination's error and propagate the error upstream by invoking the logger's
        /// `onError` closure.
        ///
        /// - Parameter destination: The destination to handle the error from.
        private func handleFailure(for destination: LogDestination) -> (Error) -> Void {

            return { [weak self] error in
                self?.onError?(destination, error)
            }
        }
    }
}

extension Log.MultiLogger {

    @resultBuilder
    public struct DestinationBuilder {

        public typealias AnyLogDestination = AnyMetadataLogDestination<MetadataKey>

        public static func buildExpression<Destination: MetadataLogDestination>(
            _ destination: Destination
        ) -> [AnyLogDestination] where Destination.MetadataKey == MetadataKey {

            [destination.eraseToAnyMetadataLogDestination()]
        }

        public static func buildExpression(_ destinations: AnyLogDestination) -> [AnyLogDestination] { [destinations] }

        public static func buildExpression(_ destinations: [AnyLogDestination]) -> [AnyLogDestination] { destinations }

        public static func buildBlock(_ destinations: [AnyLogDestination]...) -> [AnyLogDestination] {

            destinations.flatMap { $0 }
        }

        public static func buildOptional(_ destinations: [AnyLogDestination]?) -> [AnyLogDestination] {

            destinations ?? []
        }

        public static func buildEither(first destination: [AnyLogDestination]) -> [AnyLogDestination] { destination }

        public static func buildEither(second destination: [AnyLogDestination]) -> [AnyLogDestination] { destination }

        public static func buildLimitedAvailability(_ destination: [AnyLogDestination]) -> [AnyLogDestination] {

            destination
        }

        public static func buildArray(_ destinations: [[AnyLogDestination]]) -> [AnyLogDestination] {

            destinations.flatMap { $0 }
        }
    }
}
