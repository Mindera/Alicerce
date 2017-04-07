//
//  LogItemStringFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public struct LogItemStringFormatter {

    private static let defaultFormatString = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"
    public let formatString: String
    public let formatter = DateFormatter()
    public let levelColorFormatter: LogItemLevelColorFormatter
    public let levelNameFormatter: LogItemLevelNameFormatter

    // MARK:- Lifecycle

    public init(formatString: String = LogItemStringFormatter.defaultFormatString,
                levelColorFormatter: LogItemLevelColorFormatter = LogItemLevelColorDefaultFormatter(),
                levelNameFormatter: LogItemLevelNameFormatter = LogItemLevelNameDefaultFormatter()) {
        self.formatString = formatString
        self.levelColorFormatter = levelColorFormatter
        self.levelNameFormatter = levelNameFormatter
    }
}

// MARK:- LogItemFormatter

extension LogItemStringFormatter: LogItemFormatter {

    private enum SupportedDateTimeZones: String {
        case current = ""
        case utc = "UTC"
    }

    public func format(logItem: LogItem) -> String {

        var text = ""
        let phrases = formatString.components(separatedBy: "$")

        for phrase in phrases {
            guard !phrase.isEmpty else { continue }

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
                text += formatFileName(withoutSuffix: logItem.file) + remainingPhrase
            case "n":
                text += formatFileName(withSuffix: logItem.file) + remainingPhrase
            case "F":
                text += logItem.function + remainingPhrase
            case "l":
                text += String(logItem.line) + remainingPhrase
            case "D":
                text += formatDate(remainingPhrase)
            case "d":
                text += remainingPhrase
            case "Z":
                text += formatDate(remainingPhrase, timeZone: .utc)
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

        return text
    }

    //MARK:- private methods

    private func formatDate(_ dateFormat: String, timeZone: SupportedDateTimeZones = .current) -> String {

        if timeZone != .current {
            formatter.timeZone = TimeZone(abbreviation: timeZone.rawValue)
        }
        formatter.dateFormat = dateFormat
        return formatter.string(from: Date())
    }

    private func formatFileName(withSuffix file: String) -> String {

        return file.components(separatedBy: "/").last ?? ""
    }

    private func formatFileName(withoutSuffix file: String) -> String {

        let fileName = formatFileName(withSuffix:file)
        guard !fileName.isEmpty else { return "" }
        return fileName.components(separatedBy: ".").first ?? ""
    }
}
