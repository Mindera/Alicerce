//
//  StringProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

public final class StringProvider {
    
    public var minLevel: Log.Level = .error
    public var formatter: LogItemFormatter = LogItemStringFormatter()
    public var output: String = ""
    public var linefeed: String = "\n"
}

//MARK:- LogProvider

extension StringProvider: LogProvider {
    
    public func providerInstanceId() -> String {
        return "\(type(of: self))"
    }
    
    public func write(item: LogItem) {
        let formattedItem = formatter.format(logItem: item)
        if !output.characters.isEmpty {
            output += linefeed
        }
        output += "\(formattedItem)"
    }
}

