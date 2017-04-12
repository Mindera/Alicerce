//
//  Alicerce.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class Log {

    public private(set) static var destinations = [LogDestination]()

    public static let defaultLevel = Level.error

    // MARK:- Destination Management

    public class func register(_ destination: LogDestination) {
        if destinations.contains(where: { $0.instanceId == destination.instanceId }) == false {
            destinations.append(destination)
        }
    }

    public class func unregister(_ destination: LogDestination) {
        destinations = destinations.filter({ registeredDestinaton -> Bool in
            return registeredDestinaton.instanceId != destination.instanceId
        })
    }

    public class func removeAllDestinations() {
        destinations.removeAll()
    }

    // MARK:- Logging

    public class func verbose(_ message: @autoclosure () -> String,
                              file: String = #file,
                              function: String = #function,
                              line: Int = #line,
                              completion: @escaping (LogDestination, Item, Error?) -> Void = Log.defaultLogItemWrittenHandler) {

        log(level: .verbose, message: message, file: file, function: function, line: line, completion: completion)
    }

    public class func debug(_ message: @autoclosure () -> String,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line,
                            completion: @escaping (LogDestination, Item, Error?) -> Void = Log.defaultLogItemWrittenHandler) {

        log(level: .debug, message: message, file: file, function: function, line: line, completion: completion)
    }

    public class func info(_ message: @autoclosure () -> String,
                           file: String = #file,
                           function: String = #function,
                           line: Int = #line,
                           completion: @escaping (LogDestination, Item, Error?) -> Void = Log.defaultLogItemWrittenHandler) {

        log(level: .info, message: message, file: file, function: function, line: line, completion: completion)
    }

    public class func warning(_ message: @autoclosure () -> String,
                              file: String = #file,
                              function: String = #function,
                              line: Int = #line,
                              completion: @escaping (LogDestination, Item, Error?) -> Void = Log.defaultLogItemWrittenHandler) {

        log(level: .warning, message: message, file: file, function: function, line: line, completion: completion)
    }

    public class func error(_ message: @autoclosure () -> String,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line,
                            completion: @escaping (LogDestination, Item, Error?) -> Void = Log.defaultLogItemWrittenHandler) {

        log(level: .error, message: message, file: file, function: function, line: line, completion: completion)
    }

    public class func log(level: Level,
                          message: @autoclosure () -> String,
                          file: String = #file,
                          function: String = #function,
                          line: Int = #line,
                          completion: @escaping (LogDestination, Item, Error?) -> Void = Log.defaultLogItemWrittenHandler) {

        let item = Log.Item(level: level, message: message(), file: file,
                            thread: threadName(), function: function, line: line)

        for destination in destinations {
            if itemShouldBeLogged(destination: destination, item: item) {
                destination.write(item: item, completion: completion)
            }
        }
    }

    // MARK:- Private Methods

    private class func threadName() -> String {

        if Thread.isMainThread {
            return "main-thread"
        }
        else {
            if let threadName = Thread.current.name, !threadName.isEmpty {
                return threadName
            }
            else {
                return String(format: "%p", Thread.current)
            }
        }
    }

    private class func itemShouldBeLogged(destination: LogDestination, item: Log.Item) -> Bool {

        return (destination.minLevel.rawValue <= item.level.rawValue)
    }

    private class func defaultLogItemWrittenHandler(destination: LogDestination, item: Item, error: Error?) {
        if let error = error {
            fatalError("💥: Failed to log item \(item) to destination \(destination)! Error: \(error)")
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
    }
}
