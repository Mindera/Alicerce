//
//  ConsoleProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class ConsoleProvider {
    
    public var minLevel: Log.Level = .error
    public var formatter: LogItemFormatter = LogItemStringFormatter()
    public var output: ConsoleOutput = .print
}

extension ConsoleProvider {
    public enum ConsoleOutput {
        case print
        case nslog
    }
}

//MARK:- LogProvider

extension ConsoleProvider: LogProvider {
    
    public func providerInstanceId() -> String {
        return "\(type(of: self))"
    }
    
    public func write(item: LogItem) {
        let formattedLogItem = formatter.format(logItem: item)
        guard !formattedLogItem.characters.isEmpty else { return }
        
        if output == .nslog {
            NSLog("\(formattedLogItem)\n")
        }
        else if output == .print {
            print(formattedLogItem)
        }
    }
}
