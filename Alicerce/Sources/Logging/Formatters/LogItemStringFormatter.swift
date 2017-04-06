//
//  LogItemStringFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class LogItemStringFormatter {
    
    public static let defaultFormatString = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"
    public let formatString: String
    public let formatter = DateFormatter()
    public let levelColorFormatter: LogItemLevelColorFormatter
    public let levelNameFormatter: LogItemLevelNameFormatter
        
    // MARK:- Lifecycle
    
    public convenience init() {
        self.init(formatString: LogItemStringFormatter.defaultFormatString,
                  levelColorFormatter: LogItemLevelColorDefaultFormatter(),
                  levelNameFormatter: LogItemLevelNameDefaultFormatter())
    }
    
    public convenience init(formatString: String) {
        self.init(formatString: formatString,
                  levelColorFormatter: LogItemLevelColorDefaultFormatter(),
                  levelNameFormatter: LogItemLevelNameDefaultFormatter())
    }
    
    public convenience init(formatString: String, levelColorFormatter: LogItemLevelColorFormatter) {
        self.init(formatString: formatString,
                  levelColorFormatter: levelColorFormatter,
                  levelNameFormatter: LogItemLevelNameDefaultFormatter())
    }
    
    public init(formatString: String, levelColorFormatter: LogItemLevelColorFormatter, levelNameFormatter: LogItemLevelNameFormatter) {
        self.formatString = formatString
        self.levelColorFormatter = levelColorFormatter
        self.levelNameFormatter = levelNameFormatter
    }
}

// MARK:- LogItemFormatter

extension LogItemStringFormatter: LogItemFormatter {
    
    public func format(logItem: LogItem) -> String {
        
        var text = ""
        let phrases: [String] = formatString.components(separatedBy: "$")
        
        for phrase in phrases {
            if !phrase.isEmpty {
                let firstChar = phrase[phrase.startIndex]
                let rangeAfterFirstChar = phrase.index(phrase.startIndex, offsetBy: 1)..<phrase.endIndex
                let remainingPhrase = phrase[rangeAfterFirstChar]
                
                switch firstChar {
                case "L":
                    text += levelNameFormatter.labelStringForLevel(logItem.level) + remainingPhrase
                case "M":
                    text += logItem.message + remainingPhrase
                case "T":
                    text += logItem.thread + remainingPhrase
                case "N":
                    text += formatFileNameWithoutSuffix(logItem.file) + remainingPhrase
                case "n":
                    text += formatFileNameWithSuffix(logItem.file) + remainingPhrase
                case "F":
                    text += logItem.function + remainingPhrase
                case "l":
                    text += String(logItem.line) + remainingPhrase
                case "D":
                    text += formatDate(remainingPhrase)
                case "d":
                    text += remainingPhrase
                case "Z":
                    text += formatDate(remainingPhrase, timeZone: "UTC")
                case "z":
                    text += remainingPhrase
                case "C":
                    text += levelColorFormatter.escape
                        + levelColorFormatter.colorStringForLevel(logItem.level)
                        + remainingPhrase
                case "c":
                    text += levelColorFormatter.reset
                        + remainingPhrase
                default:
                    text += phrase
                }
            }
        }
        
        return text
    }
    
    //MARK:- private methods
    
    private func formatDate(_ dateFormat: String, timeZone: String = "") -> String {
        
        if !timeZone.isEmpty {
            formatter.timeZone = TimeZone(abbreviation: timeZone)
        }
        formatter.dateFormat = dateFormat
        return formatter.string(from: Date())
    }
    
    private func formatFileNameWithSuffix(_ file: String) -> String {
        
        let fileParts = file.components(separatedBy: "/")
        if let lastPart = fileParts.last {
            return lastPart
        }
        
        return ""
    }
    
    private func formatFileNameWithoutSuffix(_ file: String) -> String {
        
        let fileName = formatFileNameWithSuffix(file)
        if !fileName.isEmpty {
            let fileNameParts = fileName.components(separatedBy: ".")
            if let firstPart = fileNameParts.first {
                return firstPart
            }
        }
        
        return ""
    }
}
