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
    
    public class func register(provider: LogProvider) {
        let matchingProviders = self.providers.filter { (registeredProvider) -> Bool in
            return registeredProvider.providerInstanceId() == provider.providerInstanceId()
        }
        
        if matchingProviders.count <= 0 {
            self.providers.append(provider)
        }
    }
    
    public class func unregister(provider: LogProvider) {
        self.providers = self.providers.filter({ (registeredProvider) -> Bool in
            return registeredProvider.providerInstanceId() != provider.providerInstanceId()
        })
    }
    
    public class func removeAllProviders() {
        self.providers.removeAll()
    }
    
    // MARK:- Logging
    
    public class func verbose(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    
        self.log(level: .verbose, message: message, file: file, function: function, line: line)
    }

    public class func debug(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        self.log(level: .debug, message: message, file: file, function: function, line: line)
    }

    public class func info(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        self.log(level: .info, message: message, file: file, function: function, line: line)
    }

    public class func warning(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        self.log(level: .warning, message: message, file: file, function: function, line: line)
    }

    public class func error(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        self.log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    public class func log(level: Level, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        let item = LogItem(level: level, message: message, file: file, thread: self.threadName(), function: function, line: line)
        for provider in self.providers {
            if self.itemShouldBeLogged(provider: provider, item: item) {
                provider.write(item: item)
            }
        }
    }
    
    // MARK:- Private Methods
    
    private class func threadName() -> String {
        
        if Thread.isMainThread {
            return ""
        }
        else {
            let threadName = Thread.current.name
            if let threadName = threadName, !threadName.isEmpty {
                return threadName
            }
            else {
                return String(format: "%p", Thread.current)
            }
        }
    }
    
    private class func itemShouldBeLogged(provider: LogProvider, item: LogItem) -> Bool {
        
        if (provider.minLevel.rawValue <= item.level.rawValue) {
            return true
        }
        
        return false
    }
}

extension Log {
    public enum Level: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
    }
}
