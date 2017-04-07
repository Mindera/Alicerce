//
//  Log+ConsoleProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public class ConsoleProvider: LogProvider {

        public enum ConsoleOutput {
            case print
            case nslog
        }

        public var minLevel: Log.Level = .error
        public var formatter: LogItemFormatter = Log.ItemStringFormatter()
        public var output: ConsoleOutput = .print

        public func providerInstanceId() -> String {
            return "\(type(of: self))"
        }

        public func write(item: Item) {
            let formattedLogItem = formatter.format(logItem: item)
            guard !formattedLogItem.characters.isEmpty else { return }

            switch output {
            case .print:
                print(formattedLogItem)
            case .nslog:
                NSLog("\(formattedLogItem)\n")
            }
        }
    }
}
