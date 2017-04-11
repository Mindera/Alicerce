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
        public var minLevel = Log.Level.error
        public var formatter: LogItemFormatter = Log.StringLogItemFormatter()

        //MARK:- lifecycle

        public init(dispatchQueue: DispatchQueue = DispatchQueue(label: ConsoleLogDestination.dispatchQueueLabel)) {
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
