//
//  LevelColorBashFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

final class LevelColorBashFormatter {

}

extension LevelColorBashFormatter: LevelColorFormatterProtocol {
    
    internal var reset: String { return "\u{001b}[0m" }
    internal var escape: String { return "\u{001b}[38;5;" }
    
    internal func colorStringForLevel(_ level: Log.Level) -> String {
        
        var color = ""
        switch level {
        case .debug:
            color = "35m"
        case .info:
            color = "38m"
        case .warning:
            color = "178m"
        case .error:
            color = "197m"
        default:
            color = "251m"
        }
        
        return color
    }
}
