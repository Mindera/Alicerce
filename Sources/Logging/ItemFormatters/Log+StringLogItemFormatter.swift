import Foundation

public extension Log {

    /// A log item formatter that outputs formatted items as strings.
    struct StringLogItemFormatter: LogItemFormatter {

        /// The formatter's format string.
        public let formatString: String

        /// The formatter's date formatter.
        public let dateFormatter: DateFormatter

        /// The formatters log level formatter.
        public let levelFormatter: LogLevelFormatter

        // MARK: - Lifecycle

        /// Creates an instance with the given format string, log level and date formatters.
        ///
        /// - Parameters:
        ///   - formatString: The formatter's format string. The default is
        /// `"$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"`
        ///   - levelFormatter: The formatter's log level formatter. The default is an instance of
        /// `DefaultLogLevelFormatter`.
        ///   - dateFormatter: The formatter's date formatter. The default is an empty instance of `DateFormatter`.
        public init(formatString: String = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M",
                    levelFormatter: LogLevelFormatter = DefaultLogLevelFormatter(),
                    dateFormatter: DateFormatter = DateFormatter()) {

            self.formatString = formatString
            self.levelFormatter = levelFormatter
            self.dateFormatter = dateFormatter
        }

        // Formats a log item into a String representation.
        ///
        /// - Parameter item: The log item to format.
        /// - Returns: A binary encoded JSON representing the formatted log item.
        // swiftlint:disable:next function_body_length
        public func format(item: Item) throws -> String {

            var text = ""
            let phrases = formatString.components(separatedBy: "$")

            for phrase in phrases {
                guard !phrase.isEmpty else { continue }

                let firstChar = phrase[phrase.startIndex]
                let rangeAfterFirstChar = phrase.index(phrase.startIndex, offsetBy: 1)..<phrase.endIndex
                let remainingPhrase = phrase[rangeAfterFirstChar]

                switch firstChar {
                case "O":
                    text += (item.module ?? "") + remainingPhrase
                case "L":
                    text += levelFormatter.labelString(for: item.level) + remainingPhrase
                case "M":
                    text += item.message + remainingPhrase
                case "T":
                    text += item.thread + remainingPhrase
                case "Q":
                    text += item.queue + remainingPhrase
                case "N":
                    text += formatFileName(withoutSuffix: item.file) + remainingPhrase
                case "n":
                    text += formatFileName(withSuffix: item.file) + remainingPhrase
                case "F":
                    text += item.function + remainingPhrase
                case "l":
                    text += String(item.line) + remainingPhrase
                case "D":
                    text += formatDate(item.timestamp, dateFormat: String(remainingPhrase))
                case "d":
                    text += remainingPhrase
                case "z":
                    text += remainingPhrase
                case "C":
                    text += levelFormatter.colorEscape
                        + levelFormatter.colorString(for: item.level)
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

        // MARK: - Private methods

        private func formatDate(_ date: Date, dateFormat: String) -> String {

            dateFormatter.dateFormat = dateFormat
            return dateFormatter.string(from: date)
        }

        private func formatFileName(withSuffix file: String) -> String {

            return file.components(separatedBy: "/").last ?? "???"
        }

        private func formatFileName(withoutSuffix file: String) -> String {

            return formatFileName(withSuffix: file).components(separatedBy: ".").first ?? "???"
        }
    }
}
