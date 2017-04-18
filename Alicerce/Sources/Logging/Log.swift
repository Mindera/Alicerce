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

    public static let defaultLevel = Level.error
    public var errorClosure: ((LogDestination, Item, Error) -> ())?

    // MARK:- Destination Management

    public func register(_ destination: LogDestination) {

        if destinations.contains(where: { $0.instanceId == destination.instanceId }) == false {
            destinations.append(destination)
            if let fallibleDestination = destination as? LogDestinationFallible {
                fallibleDestination.errorClosure = genericFallibleDestinationErrorHandler
            }
        }
    }

    public func unregister(_ destination: LogDestination) {
        destinations = destinations.filter { registeredDestinaton -> Bool in
            return registeredDestinaton.instanceId != destination.instanceId
        }
    }

    public func removeAllDestinations() {
        destinations.removeAll()
    }

    // MARK:- Logging

    public func verbose(_ message: @autoclosure () -> String,
                        file: StaticString = #file,
                        function: String = #function,
                        line: UInt = #line) {

        log(level: .verbose, message: message, file: file, function: function, line: line)
    }

    public func debug(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: String = #function,
                      line: UInt = #line) {

        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    public func info(_ message: @autoclosure () -> String,
                     file: StaticString = #file,
                     function: String = #function,
                     line: UInt = #line) {

        log(level: .info, message: message, file: file, function: function, line: line)
    }

    public func warning(_ message: @autoclosure () -> String,
                        file: StaticString = #file,
                        function: String = #function,
                        line: UInt = #line) {

        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    public func error(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: String = #function,
                      line: UInt = #line) {

        log(level: .error, message: message, file: file, function: function, line: line)
    }

    public func log(level: Level,
                    message: @autoclosure () -> String,
                    file: StaticString = #file,
                    function: String = #function,
                    line: UInt = #line) {

        let item = Item(level: level, message: message(), file: file,
                        thread: Thread.threadName(), function: function, line: line)

        for destination in destinations {
            if itemShouldBeLogged(destination: destination, item: item) {
                destination.write(item: item)
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
