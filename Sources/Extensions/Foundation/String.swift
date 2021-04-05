import Foundation

public extension String {

    /// Returns the receiver casted to an `NSString`
    var nsString: NSString {
        return self as NSString
    }

    /// Returns a string object containing the characters of the receiver that lie within a given range.
    ///
    /// - Parameter nsRange: A range. The range must not exceed the bounds of the receiver.
    /// - Returns: A string object containing the characters of the receiver that lie within aRange.
    func substring(with nsRange: NSRange) -> String {
        return nsString.substring(with: nsRange) as String
    }
}

public extension String {

    /// Attempts conversion of the receiver to a boolean value, according to the following rules:
    ///
    /// - true: `"true", "yes", "1"` (allowing case variations)
    /// - false: `"false", "no", "0"` (allowing case variations)
    ///
    /// If none of the following rules is verified, `nil` is returned.
    ///
    /// - returns: an optional boolean which will have the converted value, or `nil` if the conversion failed.
    func toBool() -> Bool? {
        switch lowercased() {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: return nil
        }
    }
}

public extension String {

    /// Returns a localized string using the receiver as the key.
    var localized: String {
        return NSLocalizedString(self, comment: self)
    }

    func localized(with arguments: [CVarArg]) -> String {
        return String(format: localized, arguments: arguments)
    }

    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }
}

public extension String {

    /// Creates a string from the `dump` output of the given value.
    init<T>(dumping x: T) {
        self.init()
        dump(x, to: &self)
    }
}

extension String {

    /// Replaces occurrences of multiple `Character`s with corresponding `String` values using the given mapping, while
    /// skipping (filtering out) an optional set of characters from the output. Being backed by a `Scanner`, a single
    /// pass is made over the receiver.
    ///
    /// - Parameters:
    ///   - replacementMap: A dictionary containing the replacement mapping `Character` -> `String`.
    ///   - charactersToBeSkipped: An optional set of characters to skip (i.e. filter out from the input).
    /// - Returns: A modified version of the receiver with the replacement mapping applied.
    public func replacingOccurrencesOfCharacters(
        in replacementMap: [Character: String],
        skippingCharactersIn charactersToBeSkipped: CharacterSet? = nil
    ) -> String {

        guard !replacementMap.isEmpty else { return self }

        let matchSet = CharacterSet(charactersIn: replacementMap.keys.reduce(into: "") { $0 += String($1) })
            .union(charactersToBeSkipped ?? CharacterSet())

        var final = ""

        let scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = charactersToBeSkipped

        while !scanner.isAtEnd {

            // copy everything until finding a character to be replaced or skipped
            var collector: NSString? = ""
            if scanner.scanUpToCharacters(from: matchSet, into: &collector), let collector = collector {
                final.append(collector as String)
            }

            // exit early if we're already at the end
            guard !scanner.isAtEnd else { break }

            // find and replace matching character if needed
            replacementMap
                .first { match, _ in scanner.scanString(String(match), into: nil) }
                .flatMap { _, replacement in final.append(replacement) }
        }

        return final
    }
}

extension String {

    public static let nonBreakingSpace = String(Character.nonBreakingSpace)
    public static let nonBreakingHyphen = String(Character.nonBreakingHyphen)
    public static let wordJoiner = String(Character.wordJoiner)
    public static let emDash = String(Character.emDash)
    public static let enDash = String(Character.enDash)

    /// Returns a non line breaking version of `self`. Line breaking characters occurrences are replaced with
    /// corresponding non line breaking variants when existent. Otherwise, word joiner characters are attached to them
    /// to make them non line breaking.
    ///
    /// - Important: Any existing newline characters are preserved.
    ///
    /// The character mapping is:
    ///  - space (" ") -> non breaking space (`U+2028`)
    ///  - hyphen ("-") -> non breaking hyphen (`U+00A0`)
    ///  - em dash ("—") -> word joiner (`U+2060`) + em dash + word joiner (`U+2060`)
    ///  - em dash ("–") -> word joiner (`U+2060`) + en dash + word joiner (`U+2060`)
    ///  - question mark ("?") -> question mark + word joiner (`U+2060`)
    ///  - closing brace ("}") -> closing brace + word joiner (`U+2060`)
    ///
    /// - Returns: A modified version of the receiver without line breaking characters.
    public func nonLineBreaking() -> String {

        replacingOccurrencesOfCharacters(
            in: [
                " ": String.nonBreakingSpace,
                "-": String.nonBreakingHyphen,
                .emDash: String([.wordJoiner, .emDash, .wordJoiner]),
                .enDash: String([.wordJoiner, .enDash, .wordJoiner]),
                "?": "?" + .wordJoiner,
                "}": "}" + .wordJoiner
            ],
            skippingCharactersIn: nil
        )
    }
}
