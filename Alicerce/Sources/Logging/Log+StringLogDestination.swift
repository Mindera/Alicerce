//
//  Log+StringLogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

public extension Log {

    public class StringLogDestination: LogDestination {

        public var minLevel = Log.Level.error
        public var formatter: LogItemFormatter = Log.StringLogItemFormatter()
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
