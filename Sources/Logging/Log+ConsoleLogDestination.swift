//
//  Log+ConsoleLogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public class ConsoleLogDestination: LogDestination {

        public let queue: Queue
        public let minLevel: Level
        public let formatter: LogItemFormatter
        public private(set) var writtenItems: Int = 0

        //MARK:- lifecycle

        public init(minLevel: Level = .error,
                    formatter: LogItemFormatter = StringLogItemFormatter(),
                    queue: Queue = Queue(label: "com.mindera.alicerce.log.destination.console")) {

            self.minLevel = minLevel
            self.formatter = formatter
            self.queue = queue
        }

        //MARK:- public methods

        public func write(item: Item) {
            queue.dispatchQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                let formattedLogItem = strongSelf.formatter.format(logItem: item)
                guard !formattedLogItem.isEmpty else { return }
                print(formattedLogItem)
                strongSelf.writtenItems += 1
            }
        }
    }
}
