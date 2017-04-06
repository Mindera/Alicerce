//
//  LogItemLevelColorDefaultFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

public final class LogItemLevelColorDefaultFormatter {

}

extension LogItemLevelColorDefaultFormatter: LogItemLevelColorFormatter {

    public var escape: String { return "" }
    public var reset: String { return "" }

    public func colorStringForLevel(_ level: Log.Level) -> String {

        switch level {
        case .debug:
            return "📗  "
        case .info:
            return "📘  "
        case .warning:
            return "📙  "
        case .error:
            return "📕  "
        case .verbose:
            return "📔  "
        }
    }
}
