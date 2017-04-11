//
//  Log+StringLogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public class StringLogDestination: LogDestination {

        private static let dispatchQueueLabel = "com.mindera.Alicerce.StringLogDestination"

        public private(set) var dispatchQueue: DispatchQueue
        public private(set) var minLevel: Level
        public private(set) var formatter: LogItemFormatter
        public var output = ""
        public var linefeed = "\n"

        //MARK:- lifecycle

        public init(
            minLevel: Level = Log.Level.error,
            formatter: LogItemFormatter = Log.StringLogItemFormatter(),
            dispatchQueue: DispatchQueue = DispatchQueue(label: StringLogDestination.dispatchQueueLabel)) {

            self.minLevel = minLevel
            self.formatter = formatter
            self.dispatchQueue = dispatchQueue
        }

        //MARK:- public methods

        public func write(item: Item) {
            let formattedItem = formatter.format(logItem: item)
            if !output.characters.isEmpty {
                output += linefeed
            }
            output += "\(formattedItem)"
        }
    }
}
