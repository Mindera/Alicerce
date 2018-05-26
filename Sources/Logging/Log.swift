//
//  Alicerce.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class Log: Logger {

    public enum Error: Swift.Error {
        case duplicateDestination(LogDestination.ID)
        case inexistentDestination(LogDestination.ID)
    }

    /// Queue object used to specify `DispatchQueue`'s used in log destinations, ensuring they are serial queues of the
    /// specified QoS, targeting an optional queue.
    public final class Queue {
        public let dispatchQueue: DispatchQueue

        public init(label: String, qos: DispatchQoS = .background, target: DispatchQueue? = nil) {
            dispatchQueue = DispatchQueue(label: label, qos: qos, target: target)
        }
    }

    public private(set) var destinations = Atomic<[LogDestination]>([])
    public var errorClosure: ((LogDestination, Item, Swift.Error) -> Void)? = { destination, item, error in
        print("💥[Alicerce.Log]: Failed to log item \(item) to destination '\(destination.id)' with error: \(error)")
    }

    public init() {}

    // MARK: - Destination Management

    public func register(_ destination: LogDestination) throws {

        try destinations.modify {
            guard $0.contains(where: { $0.id == destination.id }) == false
            else { throw Error.duplicateDestination(destination.id) }

            $0.append(destination)
        }
    }

    public func unregister(_ destination: LogDestination) throws {

        try destinations.modify {
            guard $0.contains(where: { $0.id == destination.id }) else {
                throw Error.inexistentDestination(destination.id)
            }

            $0 = $0.filter { $0.id != destination.id }
        }
    }

    public func removeAllDestinations() {

        destinations.value = []
    }

    // MARK: - Logging

    public func verbose(_ message: @autoclosure () -> String,
                        file: StaticString = #file,
                        function: StaticString = #function,
                        line: UInt = #line) {

        log(level: .verbose, message: message, file: file, function: function, line: line)
    }

    public func debug(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line) {

        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    public func info(_ message: @autoclosure () -> String,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line) {

        log(level: .info, message: message, file: file, function: function, line: line)
    }

    public func warning(_ message: @autoclosure () -> String,
                        file: StaticString = #file,
                        function: StaticString = #function,
                        line: UInt = #line) {

        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    public func error(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line) {

        log(level: .error, message: message, file: file, function: function, line: line)
    }

    // MARK: - Private Methods

    private func log(level: Level,
                     message: @autoclosure () -> String,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line) {

        destinations.withValue {
            let matchingDestinations = $0.filter { level.isAbove(minLevel: $0.minLevel) }

            guard matchingDestinations.isEmpty == false else { return }

            // only create the item if effectively needed (thus taking advantage of @autoclosure)
            let item = Item(level: level,
                            message: message(),
                            file: String(describing: file),
                            thread: Thread.threadName(),
                            function: String(describing: function),
                            line: line)

            let logFailure: (LogDestination, Item) -> (Swift.Error) -> Void = { destination, item in
                return { [weak self] error in
                    self?.errorClosure?(destination, item, error)
                }
            }

            matchingDestinations.forEach {
                $0.write(item: item, failure: logFailure($0, item))
            }
        }
    }
}

extension Log {
    public enum Level: Int {
        case verbose
        case debug
        case info
        case warning
        case error

        func isAbove(minLevel: Level) -> Bool {
            return minLevel.rawValue <= rawValue
        }
    }
}
