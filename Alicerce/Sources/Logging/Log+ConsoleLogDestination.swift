//
//  Log+ConsoleLogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public class ConsoleLogDestination: LogDestination
    {
        private static let dispatchQueueLabel = "com.mindera.Alicerce.ConsoleLogDestination"

        public private(set) var dispatchQueue: DispatchQueue
        public private(set) var minLevel: Level
        public private(set) var formatter: LogItemFormatter

        //MARK:- lifecycle

        public init(
            minLevel: Level = Log.Level.error,
            formatter: LogItemFormatter = Log.StringLogItemFormatter(),
            dispatchQueue: DispatchQueue = DispatchQueue(label: ConsoleLogDestination.dispatchQueueLabel)) {

            self.minLevel = minLevel
            self.formatter = formatter
            self.dispatchQueue = dispatchQueue
        }

        //MARK:- public methods

        public func write(item: Item) {
            dispatchQueue.sync {
                let formattedLogItem = formatter.format(logItem: item)
                guard !formattedLogItem.characters.isEmpty else { return }
                print(formattedLogItem)
            }
        }
    }
}
