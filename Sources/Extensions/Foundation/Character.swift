import Foundation

extension Character {

    static let lineSeparator: Character = "\u{2028}"
    static let nonBreakingSpace: Character = "\u{00a0}"
    static let nonBreakingHyphen: Character = "\u{2011}"
    static let wordJoiner: Character = "\u{2060}"
    static let emDash: Character = "\u{2013}" // —
    static let enDash: Character = "\u{2014}" // –

    // from `CharacterSet.newlines`
    static let newlines: [Character] = ["\u{A}", "\u{B}", "\u{C}", "\u{D}", "\u{85}", "\u{2028}", "\u{2029}"]
}
