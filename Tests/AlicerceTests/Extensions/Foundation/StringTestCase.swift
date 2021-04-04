import XCTest
@testable import Alicerce

class StringTestCase: XCTestCase {

    // nsString

    func testNSString_ShouldReturnCastedString() {

        let string = "TestString"
        
        let nsString = string.nsString
        let string2 = nsString as String

        XCTAssertEqual(string, string2)
    }
    
    // substring

    func testSubstring_ShouldReturnCorrectSubstring() {

        let string = "TestString"
        let substring1 = string.substring(with: NSRange(location: 0, length: 4))
        let substring2 = string.substring(with: NSRange(location: 4, length: 6))

        XCTAssertEqual(substring1, "Test")
        XCTAssertEqual(substring2, "String")
    }

    // toBool()

    func testToBool_ShouldReturnCorrectValue() {

        XCTAssertEqual("true".toBool(), true)
        XCTAssertEqual("TRUE".toBool(), true)
        XCTAssertEqual("yes".toBool(), true)
        XCTAssertEqual("YES".toBool(), true)
        XCTAssertEqual("1".toBool(), true)

        XCTAssertEqual("false".toBool(), false)
        XCTAssertEqual("FALSE".toBool(), false)
        XCTAssertEqual("no".toBool(), false)
        XCTAssertEqual("NO".toBool(), false)
        XCTAssertEqual("0".toBool(), false)
    }

    // localized

    func testLocalized_WithNonExistingLocalizedString_ShouldReturnSelf() {

        // can't test the happy path, because the getter uses the default bundle and making it a function would suck 😇

        XCTAssertEqual("mock.non-localized".localized, "mock.non-localized")
    }

    // init(dumping:)

    func testInitDumping_ShouldReturnOutputEqualToDump() {

        let value = 1337

        let intDump = String(dumping: value)

        var dumpString = ""
        dump(value, to: &dumpString)

        XCTAssertEqual(intDump, dumpString)
    }

    // replacingOccurrencesOfCharacters(in:skippingCharactersIn:)

    func testReplacingOccurrencesOfCharacters_WithEmptyMap_ShouldReturnSelf() {

        let text = "The quick brown fox jumps over the lazy dog"

        XCTAssertEqual(text.replacingOccurrencesOfCharacters(in: [:], skippingCharactersIn: nil), text)
    }

    func testReplacingOccurrencesOfCharacters_WithMatchingCharactersInSingleEntryMapAndNilSkippingCharacterSet_ShouldReplaceOccurrences() {

        let original = "The quick brown fox jumps over the lazy dog"
        let expected = "The_quick_brown_fox_jumps_over_the_lazy_dog"

        XCTAssertEqual(
            original.replacingOccurrencesOfCharacters(in: [.init(" "): "_"], skippingCharactersIn: nil),
            expected
        )
    }

    func testReplacingOccurrencesOfCharacters_WithMatchingCharactersInMultiEntryMapAndNilSkippingCharacterSet_ShouldReplaceOccurrences() {

        let original = "0123456789ABCDEF"
        let expected = "0123456789abcdef"

        XCTAssertEqual(
            original.replacingOccurrencesOfCharacters(
                in: [
                    .init("A"): "a",
                    .init("B"): "b",
                    .init("C"): "c",
                    .init("D"): "d",
                    .init("E"): "e",
                    .init("F"): "f",
                ],
                skippingCharactersIn: nil
            ),
            expected
        )
    }

    func testReplacingOccurrencesOfCharacters_WithMatchingCharactersInMapAndMatchingCharactersInSkippingCharacterSet_ShouldReplaceOccurrencesAndSkip() {

        let original = "0123456789ABCDEF_0A0B0C0D0E0F0"
        let expected = "abcdef_abcdef"

        XCTAssertEqual(
            original.replacingOccurrencesOfCharacters(
                in: [
                    .init("A"): "a",
                    .init("B"): "b",
                    .init("C"): "c",
                    .init("D"): "d",
                    .init("E"): "e",
                    .init("F"): "f",
                ],
                skippingCharactersIn: .decimalDigits
            ),
            expected
        )
    }

    // nonLineBreaking()

    func testNonLineBreaking_WithNoLineBreakingCharactersInString_ShouldReturnSelf() {

        let original = "0123456789ABCDEF"

        XCTAssertEqual(original.nonLineBreaking(), original)
    }

    func testNonLineBreaking_WithLineBreakingCharactersInString_ShouldReturnANonLineBreakingVersion() {

        let original = "The quick-brown\(String.emDash)fox\(String.enDash)jumps?over{the}lazy dog"
        let expected =
            """
            The\(String.nonBreakingSpace)quick\(String.nonBreakingHyphen)brown\
            \(String([.wordJoiner, .emDash, .wordJoiner]))fox\
            \(String([.wordJoiner, .enDash, .wordJoiner]))jumps\
            ?\(String.wordJoiner)over{the}\(String.wordJoiner)lazy\(String.nonBreakingSpace)dog
            """

        XCTAssertEqual(original.nonLineBreaking(), expected)
    }

    func testNonLineBreaking_WithLineBreakingCharactersAndNewlinesInString_ShouldReturnANonLineBreakingVersion() {

        let original =
            """
            \nThe quick-brown\u{85}\(String.emDash)fox\n\(String.enDash)jumps?\u{2028}\u{2029}over{the}lazy dog\n
            \u{A}.\u{B},\u{C};\u{D}
            """
        
        let expected =
            """
            \nThe\(String.nonBreakingSpace)quick\(String.nonBreakingHyphen)brown\u{85}\
            \(String([.wordJoiner, .emDash, .wordJoiner]))fox\n\
            \(String([.wordJoiner, .enDash, .wordJoiner]))jumps\
            ?\(String.wordJoiner)\u{2028}\u{2029}over\
            {the}\(String.wordJoiner)lazy\(String.nonBreakingSpace)dog\n
            \u{A}.\u{B},\u{C};\u{D}
            """

        XCTAssertEqual(original.nonLineBreaking(), expected)
    }
}
