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

        public typealias OutputClosure = ((Level, String) -> Void)

        public let minLevel: Level
        public let formatter: LogItemFormatter
        private let queue: Queue
        private let outputClosure: OutputClosure

        // MARK: - Lifecycle

        public init(minLevel: Level = .error,
                    formatter: LogItemFormatter = StringLogItemFormatter(),
                    queue: Queue = Queue(label: "com.mindera.alicerce.log.destination.console"),
                    outputClosure: @escaping OutputClosure = { (level, message) in print(message) }) {

            self.minLevel = minLevel
            self.formatter = formatter
            self.queue = queue
            self.outputClosure = outputClosure
        }

        // MARK: - Public methods

        public func write(item: Log.Item, failure: @escaping (Swift.Error) -> ()) {
            queue.dispatchQueue.async { [unowned self] in
                let formattedLogItem = self.formatter.format(logItem: item)
                guard !formattedLogItem.isEmpty else { return }

                self.outputClosure(item.level, formattedLogItem)
            }
        }
    }
}
