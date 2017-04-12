//
//  Log+StringLogItemFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public struct StringLogItemFormatter: LogItemFormatter {

        private static let defaultFormatString = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"
        public let formatString: String
        public let dateFormatter: DateFormatter
        public let levelFormatter: LogItemLevelFormatter

        // MARK:- Lifecycle

        public init(formatString: String = StringLogItemFormatter.defaultFormatString,
                    levelFormatter: LogItemLevelFormatter = DefaultLogItemLevelFormatter(),
                    dateFormatter: DateFormatter = DateFormatter()) {
            self.formatString = formatString
            self.levelFormatter = levelFormatter
            self.dateFormatter = dateFormatter
        }

        private enum SupportedDateTimeZones: String {
            case current = ""
            case utc = "UTC"
        }

        public func format(logItem: Log.Item) -> String {

            var text = ""
            let phrases = formatString.components(separatedBy: "$")

            for phrase in phrases {
                guard !phrase.isEmpty else { continue }

                let firstChar = phrase[phrase.startIndex]
                let rangeAfterFirstChar = phrase.index(phrase.startIndex, offsetBy: 1)..<phrase.endIndex
                let remainingPhrase = phrase[rangeAfterFirstChar]

                switch firstChar {
                case "L":
                    text += levelFormatter.labelString(for: logItem.level) + remainingPhrase
                case "M":
                    text += logItem.message + remainingPhrase
                case "T":
                    text += logItem.thread + remainingPhrase
                case "N":
                    text += formatFileName(withoutSuffix: logItem.file) ?? "" + remainingPhrase
                case "n":
                    text += formatFileName(withSuffix: logItem.file) ?? "" + remainingPhrase
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
                    text += levelFormatter.colorEscape
                        + levelFormatter.colorString(for: logItem.level)
                        + remainingPhrase
                case "c":
                    text += levelFormatter.colorReset
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
                dateFormatter.timeZone = TimeZone(abbreviation: timeZone.rawValue)
            }
            dateFormatter.dateFormat = dateFormat
            return dateFormatter.string(from: Date())
        }

        private func formatFileName(withSuffix file: String) -> String? {
            
            return file.components(separatedBy: "/").last
        }
        
        private func formatFileName(withoutSuffix file: String) -> String? {

            return formatFileName(withSuffix: file)?.components(separatedBy: ".").first
        }
    }
}
