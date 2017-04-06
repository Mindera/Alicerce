//
//  LogItemLevelColorDefaultFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

final class LogItemLevelColorDefaultFormatter {

}

extension LogItemLevelColorDefaultFormatter: LogItemLevelColorFormatter {
    
    internal var escape: String { return "" }
    internal var reset: String { return "" }
    
    internal func colorStringForLevel(_ level: Log.Level) -> String {

        var color = ""
        switch level {
        case .debug:
            color = "📗 "
        case .info:
            color = "📘 "
        case .warning:
            color = "📙 "
        case .error:
            color = "📕 "
        default:
            color = "📔 "
        }
        
        return color
    }
}
