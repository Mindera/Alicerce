//
//  StringProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

final class StringProvider {
    
    internal var minLevel: Log.Level = .error
    internal var formatter: LogItemFormatterProtocol = LogItemStringFormatter()
    internal var output: String = ""
    internal var linefeed: String = "\n"
}

//MARK:- ProviderProtocol

extension StringProvider: ProviderProtocol {
    
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

