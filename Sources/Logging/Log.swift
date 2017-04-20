//
//  Alicerce.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class Log: Logger {

    // The Log.Queue class is used to specify the DispatchQueue used in the log destinations
    // and ensures that it is a serial queue of the specified QoS.
    public final class Queue {
        public let dispatchQueue: DispatchQueue

        public init(label: String, qos: DispatchQoS = .background) {
            self.dispatchQueue = DispatchQueue(label: label, qos: qos)
        }
    }

    public private(set) var destinations = [LogDestination]()
    public var errorClosure: ((LogDestination, Item, Error) -> ())?

    private let queue: DispatchQueue

    // MARK:- Lifecycle

    public init(qos: DispatchQoS = .default) {
        queue = DispatchQueue(label: "com.mindera.alicerce.log.queue", qos: qos)
    }

    // MARK:- Destination Management

    public func register(_ destination: LogDestination) {

        queue.sync { [unowned self] in
            if self.destinations.contains(where: { $0.instanceId == destination.instanceId }) == false {
                self.destinations.append(destination)
                if let fallibleDestination = destination as? LogDestinationFallible {
                    fallibleDestination.errorClosure = self.genericFallibleDestinationErrorHandler
                }
            }
        }
    }

    public func unregister(_ destination: LogDestination) {

        queue.sync { [unowned self] in
            self.destinations = self.destinations.filter { registeredDestinaton -> Bool in
                return registeredDestinaton.instanceId != destination.instanceId
            }
        }
    }

    public func removeAllDestinations() {

        queue.sync { [unowned self] in
            self.destinations.removeAll()
        }
    }

    // MARK:- Logging

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

    public func log(level: Level,
                    message: @autoclosure () -> String,
                    file: StaticString = #file,
                    function: StaticString = #function,
                    line: UInt = #line) {

        let item = Item(level: level,
                        message: message(),
                        file: String(describing: file),
                        thread: Thread.threadName(),
                        function: String(describing: function),
                        line: line)

        queue.sync { [unowned self] in
            for destination in self.destinations {
                if self.itemShouldBeLogged(destination: destination, item: item) {
                    destination.write(item: item)
                }
            }
        }
    }

    // MARK:- Private Methods

    private func itemShouldBeLogged(destination: LogDestination, item: Item) -> Bool {

        return (destination.minLevel.rawValue <= item.level.rawValue)
    }

    private func genericFallibleDestinationErrorHandler(destination: LogDestination, item: Item, error: Error) {
        print("💥: Failed to log item \(item) to destination \(destination)! Error: \(error)")
        self.errorClosure?(destination, item, error)
    }
}

extension Log {
    public enum Level: Int {
        case verbose
        case debug
        case info
        case warning
        case error
    }
}
