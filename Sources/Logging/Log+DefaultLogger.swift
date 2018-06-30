// Copyright © 2018 Mindera. All rights reserved.

import Foundation

extension Log {

    /// An error produced by `DefaultLogger` instances.
    public enum DefaultLoggerError: Error {
        /// A destination with the same id already registered.
        case duplicateDestination(LogDestination.ID)

        /// A destination with the given id isn't registered.
        case inexistentDestination(LogDestination.ID)

        /// The module is already registered.
        case duplicateModule(String)

        /// The module isn't registered
        case inexistentModule(String)
    }

    /// A default implementation of a `Logger`, allowing multiple log destinations to which logs can be written
    /// concurrently.
    public final class DefaultLogger<Module: LogModule>: Logger {

        /// The logger's registered destinations.
        public private(set) var destinations = Atomic<[LogDestination]>([])

        /// The logger's registered modules.
        public private(set) var modules = Atomic<[Module : Log.Level]>([:])

        /// The logger's error callback closure, invoked whenever any of its destinations fails an operation.
        public var onError: ((LogDestination, Error) -> ())? = { destination, error in
            print("💥[Alicerce.Log]: Failed to perform operation in destination '\(destination.id)' with error: \(error)")
        }

        /// Creates an instance of a logger.
        public init() {}

        // MARK: - Destination Management

        /// Registers a destination in the logger, and starts sending any new logging events to it.
        /// This method is thread safe.
        ///
        /// - Parameter destination: The log destination to register.
        /// - Throws: A `DefaultLoggerError.duplicateDestination` error if a destination with the same `id` is already
        /// registered.
        public func registerDestination(_ destination: LogDestination) throws {

            try destinations.modify {
                guard $0.contains(where: { $0.id == destination.id }) == false else {
                    throw DefaultLoggerError.duplicateDestination(destination.id)
                }

                $0.append(destination)
            }
        }

        /// Unregisters a destination from the logger, preventing any new logging events from being sent to it.
        ///
        /// - Parameter destination: The log destination to unregister.
        /// - Throws: A `DefaultLoggerError.inexistentDestination` error if a destination with the same `id` isn't
        /// registered.
        public func unregisterDestination(_ destination: LogDestination) throws {

            try destinations.modify {
                guard $0.contains(where: { $0.id == destination.id }) else {
                    throw DefaultLoggerError.inexistentDestination(destination.id)
                }

                $0 = $0.filter { $0.id != destination.id }
            }
        }

        // MARK: - Module Management

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
        /// - Throws: A `DefaultLoggerError.duplicateModule` error if a module with the same `rawValue` is already
        /// registered.
        public func registerModule(_ module: Module, minLevel: Level) throws {

            try modules.modify {
                guard $0[module] == nil else { throw DefaultLoggerError.duplicateModule(module.rawValue) }

                $0[module] = minLevel
            }
        }

        /// Unregisters a module from the logger, taking it into account when filtering any new log messages (if logged
        /// with a non `nil` module)
        ///
        /// - SeeAlso: `registerModule(_:minLevel:)`
        ///
        /// - Parameter module: The module to be unregistered.
        /// - Throws: A `DefaultLoggerError.inexistentModule` error if a module with the same `rawValue` isn't
        /// registered.
        public func unregisterModule(_ module: Module) throws {

            try modules.modify {
                guard let _ = $0.removeValue(forKey: module) else {
                    throw DefaultLoggerError.inexistentModule(module.rawValue)
                }
            }
        }

        // MARK: - Logging

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
        public func log(module: Module?,
                        level: Level,
                        message: @autoclosure () -> String,
                        file: StaticString = #file,
                        line: UInt = #line,
                        function: StaticString = #function) {

            // skip module checks for `nil` modules
            if let module = module {
                guard
                    let moduleMinLevel = modules.value[module],
                    level.isAbove(minLevel: moduleMinLevel)
                else { return }
            }

            let matchingDestinations = destinations.value.filter { level.isAbove(minLevel: $0.minLevel) }

            guard matchingDestinations.isEmpty == false else { return }

            // only create the item if effectively needed (thus taking advantage of @autoclosure)
            let item = Item(timestamp: Date(),
                            module: module?.rawValue,
                            level: level,
                            message: message(),
                            thread: Thread.currentName,
                            queue: DispatchQueue.currentLabel,
                            file: String(describing: file),
                            line: line,
                            function: String(describing: function))

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
        public func setMetadata(_ metadata: [AnyHashable : Any]) {

            destinations.value.forEach { $0.setMetadata(metadata, onFailure: handleFailure(for: $0)) }
        }

        /// Removes custom metadata from the logger's destinations, when any previous information became outdated (e.g.
        /// user signed out).
        ///
        /// - SeeAlso: `setMetadata(_:)`
        ///
        /// - Parameter keys: The custom metadata keys to remove.
        public func removeMetadata(forKeys keys: [AnyHashable]) {

            destinations.value.forEach { $0.removeMetadata(forKeys: keys, onFailure: handleFailure(for: $0)) }
        }

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
