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
        public var minLevel = Log.Level.error
        public var formatter: LogItemFormatter = Log.StringLogItemFormatter()
        public var output = ""
        public var linefeed = "\n"

        //MARK:- lifecycle

        public init(dispatchQueue: DispatchQueue = DispatchQueue(label: StringLogDestination.dispatchQueueLabel)) {
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
