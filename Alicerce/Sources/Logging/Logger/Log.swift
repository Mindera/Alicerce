//
//  Alicerce.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class Log {

    fileprivate static var providers = Array<LogProvider>()

    public static let defaultLevel: Level = Level.error

    // MARK:- Provider Management

    internal static var providerCount: Int {
        return providers.count
    }

    public class func register(_ provider: LogProvider) {
        let matchingProviders = providers.filter { (registeredProvider) -> Bool in
            return registeredProvider.providerInstanceId() == provider.providerInstanceId()
        }

        if matchingProviders.isEmpty {
            providers.append(provider)
        }
    }

    public class func unregister(_ provider: LogProvider) {
        providers = providers.filter({ (registeredProvider) -> Bool in
            return registeredProvider.providerInstanceId() != provider.providerInstanceId()
        })
    }

    public class func removeAllProviders() {
        providers.removeAll()
    }

    // MARK:- Logging

    public class func verbose(_ message: @autoclosure () -> String,
                              file: String = #file,
                              function: String = #function,
                              line: Int = #line) {

        log(level: .verbose, message: message, file: file, function: function, line: line)
    }

    public class func debug(_ message: @autoclosure () -> String,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line) {

        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    public class func info(_ message: @autoclosure () -> String,
                           file: String = #file,
                           function: String = #function,
                           line: Int = #line) {

        log(level: .info, message: message, file: file, function: function, line: line)
    }

    public class func warning(_ message: @autoclosure () -> String,
                              file: String = #file,
                              function: String = #function,
                              line: Int = #line) {

        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    public class func error(_ message: @autoclosure () -> String,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line) {

        log(level: .error, message: message, file: file, function: function, line: line)
    }

    public class func log(level: Level,
                          message: @autoclosure () -> String,
                          file: String = #file,
                          function: String = #function,
                          line: Int = #line) {

        let item = LogItem(level: level, message: message(), file: file,
                           thread: threadName(), function: function, line: line)

        for provider in providers {
            if itemShouldBeLogged(provider: provider, item: item) {
                provider.write(item: item)
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

    private class func itemShouldBeLogged(provider: LogProvider, item: LogItem) -> Bool {

        return (provider.minLevel.rawValue <= item.level.rawValue)
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
