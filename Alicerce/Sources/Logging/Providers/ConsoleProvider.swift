//
//  ConsoleProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

final class ConsoleProvider {
    
    internal var minLevel: Log.Level = .error
    internal var formatter: LogItemFormatter = LogItemStringFormatter()
    internal var output: ConsoleOutput = .print
}

extension ConsoleProvider {
    public enum ConsoleOutput {
        case print
        case nslog
    }
}

//MARK:- LogProvider

extension ConsoleProvider: LogProvider {
    
    internal func providerInstanceId() -> String {        
        return "\(type(of: self))"
    }
    
    internal func write(item: LogItem) {
        let formattedLogItem = self.formatter.format(logItem: item)
        guard formattedLogItem.characters.count > 0 else { return }
        
        if self.output == .nslog {
            NSLog("\(formattedLogItem)\n")
        }
        else if self.output == .print {
            print(formattedLogItem)
        }
    }
}
