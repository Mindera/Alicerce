//
//  Log+StringDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

public extension Log {

    public class StringDestination: LogDestination {

        public var minLevel = Log.Level.error
        public var formatter: LogItemFormatter = Log.ItemStringFormatter()
        public var output = ""
        public var linefeed = "\n"

        public func write(item: Item) {
            let formattedItem = formatter.format(logItem: item)
            if !output.characters.isEmpty {
                output += linefeed
            }
            output += "\(formattedItem)"
        }
    }
}
