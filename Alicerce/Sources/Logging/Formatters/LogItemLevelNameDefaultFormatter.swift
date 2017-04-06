//
//  LogItemLevelNameDefaultFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

public class LogItemLevelNameDefaultFormatter {

}

extension LogItemLevelNameDefaultFormatter: LogItemLevelNameFormatter {

    public func labelStringForLevel(_ level: Log.Level) -> String {

        switch level {
        case .verbose:
            return "VERBOSE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
    }
}
