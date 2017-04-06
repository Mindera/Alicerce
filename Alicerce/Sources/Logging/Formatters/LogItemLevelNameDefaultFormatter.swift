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
        
        var str = ""
        switch level {
        case .debug:
            str = "DEBUG"
        case .info:
            str = "INFO"
        case .warning:
            str = "WARNING"
        case .error:
            str = "ERROR"
        default:
            str = "VERBOSE"
        }
        
        return str
    }
}