//
//  Log+BashLogItemLevelFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

public extension Log {

    public struct BashLogItemLevelFormatter: LogItemLevelFormatter {

        public var colorEscape = "\u{001b}[38;5;"
        public var colorReset = "\u{001b}[0m"

        public func colorString(for level: Level) -> String {

            switch level {
            case .verbose: return "251m"
            case .debug: return "35m"
            case .info: return "38m"
            case .warning: return "178m"
            case .error: return "197m"
            }
        }
    }
}
