//
//  Log+StringProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

public extension Log {

    public class StringProvider: LogProvider {

        public var minLevel: Log.Level = .error
        public var formatter: LogItemFormatter = Log.ItemStringFormatter()
        public var output: String = ""
        public var linefeed: String = "\n"

        public func providerInstanceId() -> String {
            return "\(type(of: self))"
        }

        public func write(item: Item) {
            let formattedItem = formatter.format(logItem: item)
            if !output.characters.isEmpty {
                output += linefeed
            }
            output += "\(formattedItem)"
        }
    }
}
