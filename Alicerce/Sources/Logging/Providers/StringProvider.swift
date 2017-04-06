//
//  StringProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

final class StringProvider {
    
    internal var minLevel: Log.Level = .error
    internal var formatter: LogItemFormatter = LogItemStringFormatter()
    internal var output: String = ""
    internal var linefeed: String = "\n"
}

//MARK:- LogProvider

extension StringProvider: LogProvider {
    
    internal func providerInstanceId() -> String {
        return "\(type(of: self))"
    }
    
    internal func write(item: LogItem) {
        let formattedItem = self.formatter.format(logItem: item)
        if self.output.characters.count > 0 {
            self.output += self.linefeed
        }
        self.output += "\(formattedItem)"
    }
}

