//
//  Log+StringLogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Alicerce

public extension Log {

    public class StringLogDestination: LogDestination {

        private static let dispatchQueueLabel = "com.mindera.alicerce.log.destination.string"

        public let queue: Queue
        public let minLevel: Level
        public let formatter: LogItemFormatter
        public private(set) var writtenItems: Int = 0
        public var output = ""
        public var linefeed = "\n"

        //MARK:- lifecycle

        public init(minLevel: Level = Level.error,
                    formatter: LogItemFormatter = StringLogItemFormatter(),
                    queue: Queue = Queue(label: StringLogDestination.dispatchQueueLabel)) {

            self.minLevel = minLevel
            self.formatter = formatter
            self.queue = queue
        }

        //MARK:- public methods

        public func write(item: Item) {
            queue.dispatchQueue.async { [weak self] in
                guard let strongSelf = self else { return }

                let formattedItem = strongSelf.formatter.format(logItem: item)
                if !strongSelf.output.characters.isEmpty {
                    strongSelf.output += strongSelf.linefeed
                }

                strongSelf.output += "\(formattedItem)"
                strongSelf.writtenItems += 1
            }
        }
    }
}
