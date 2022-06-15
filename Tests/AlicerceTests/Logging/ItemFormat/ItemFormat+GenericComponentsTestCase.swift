import XCTest
@testable import Alicerce

class ItemFormat_GenericComponentTestCase: XCTestCase {

    typealias Formatting = Log.ItemFormat.Formatting<String>

    typealias Value = Log.ItemFormat.Value
    typealias Property = Log.ItemFormat.Property
    typealias Group = Log.ItemFormat.Group
    typealias Map = Log.ItemFormat.Map

    // MARK: - Value

    func test_Value_ShouldOutputText() throws {

        let text = "text"

        try XCTAssertComponent(Value(text), returns: text)
    }

    // MARK: - Property

    func test_Property_WithoutTransform_ShouldOutputKeyPathValue() throws {

        let kp: KeyPath<Log.Item, String> = \.message
        let item = Log.Item.dummy(message: "🚀")

        try XCTAssertComponent(Property(kp), item: item, returns: item[keyPath: kp])
    }

    func test_Property_WithTransform_ShouldOuputTransformedKeyPathValue() throws {

        let kp: KeyPath<Log.Item, Int> = \.line
        let item = Log.Item.dummy(line: 1337)

        try XCTAssertComponent(Property(kp, String.init) , item: item, returns: String(item[keyPath: kp]))
    }

    func test_Property_WithOptionalPropertyAndNonNilValue_ShouldOutputKeyPathValue() throws {

        let kp: KeyPath<Log.Item, String?> = \.module
        let module = "🍏"
        let item = Log.Item.dummy(module: module)

        try XCTAssertComponent(Property(kp, default: "🍎"), item: item, returns: module)
    }

    func test_Property_WithOptionalPropertyAndNilValue_ShouldOutputDefaultValue() throws {

        let kp: KeyPath<Log.Item, String?> = \.module
        let item = Log.Item.dummy(module: nil)
        let `default` = "🍎"

        try XCTAssertComponent(Property(kp, default: `default`), item: item, returns: `default`)
    }

    func test_Property_WithOptionalPropertyAndTransformAndNonNilValue_ShouldOutputTransformedKeyPathValue() throws {

        let kp: KeyPath<Log.Item, String?> = \.module
        let module = "aaa"
        let item = Log.Item.dummy(module: module)
        let transform: (String) -> String = { $0.uppercased() }

        try XCTAssertComponent(Property(kp, default: "🍎", transform), item: item, returns: transform(module))
    }

    func test_Property_WithOptionalPropertyAndTransformAndNilValue_ShouldOutputDefaultValue() throws {

        let kp: KeyPath<Log.Item, String?> = \.module
        let item = Log.Item.dummy(module: nil)
        let `default` = "aaa"
        let transform: (String) -> String = {
            XCTFail("unexpected transform call!")
            return $0
        }

        try XCTAssertComponent(Property(kp, default: `default`, transform), item: item, returns: `default`)
    }

    // MARK: - Group

    func test_Group_WithPrefix_ShouldPrefixText() throws {

        let prefix = "prefix"
        let text = "|text"

        try XCTAssertComponent(Group(prefix: prefix) { text }, returns: prefix + text)
    }

    func test_Group_WithSuffix_ShouldSuffixText() throws {

        let suffix = "suffix"
        let text = "|text"

        try XCTAssertComponent(Group(suffix: suffix) { text }, returns: text + suffix)
    }

    func test_Group_WithSeparator_ShouldIntersperseSeparatorInText() throws {

        let separator = "|"
        let textA = "A"
        let textB = "B"
        let textC = "C"

        let component = Group(separator: separator) {
            textA
            textB
            textC
        }

        try XCTAssertComponent(component, returns: [textA, textB, textC].joined(separator: "|"))
    }

    func test_Group_WithPrefixAndSuffixAndSeparator_ShouldPrefixAndSuffixAndIntersperseSeparatorInText() throws {

        let prefix = "prefix"
        let separator = "|"
        let suffix = "suffix"
        let textA = "A"
        let textB = "B"
        let textC = "C"

        let component = Group(prefix: prefix, separator: separator, suffix: suffix) {
            textA
            textB
            textC
        }

        try XCTAssertComponent(component, returns: prefix + [textA, textB, textC].joined(separator: "|") + suffix)
    }

    func test_Group_WithPrefixAndSuffixAndSeparatorAndSingleText_ShouldPrefixAndSuffixAndDontIntersperseSeparatorInText() throws {

        let prefix = "prefix"
        let separator = "|"
        let suffix = "suffix"
        let text = "A"

        let component = Group<String>.init(prefix: prefix, separator: separator, suffix: suffix) { text }

        try XCTAssertComponent(component, returns: prefix + text + suffix)
    }

    func test_wrapped_ShouldPrefixAndSuffixText() throws {

        let prefix = "prefix"
        let suffix = "suffix"
        let text = "text"

        let component = Value(text).wrapped(prefix: prefix, suffix: suffix)

        try XCTAssertComponent(component, returns: prefix + text + suffix)
    }

    // MARK: - Map

    func test_Map_ShouldTransformReceiverText() throws {

        let text = "bbb"

        let component = Map(upstream: Value(text)) { $0 = $0.uppercased() }

        try XCTAssertComponent(component, initial: "aaa", returns: "aaa" + text.uppercased())
    }

    // MARK: String

    func test_map_ShouldTransformReceiverText() throws {

        let text = "bbb"

        let component = Value(text).map { $0 = $0.uppercased() }

        try XCTAssertComponent(component, initial: "aaa", returns: "aaa" + text.uppercased())
    }

    func test_uppercased_ShouldUppercaseText() throws {

        let text = "text"

        let component = Value(text).uppercased()

        try XCTAssertComponent(component, initial: "aaa", returns: "aaa" + text.uppercased())
    }

    func test_lowercased_ShouldLowercaseText() throws {

        let text = "TEXT"

        let component = Value(text).lowercased()

        try XCTAssertComponent(component, initial: "AAA", returns: "AAA" + text.lowercased())
    }

    // leftPadded

    func test_leftPadded_WithWidthBelowCount_ShouldNotLeftPadText() throws {

        let text = "text"

        let component = Value(text).leftPadded(text.count - 1)

        try XCTAssertComponent(component, returns: text)
    }

    func test_leftPadded_WithWidthEqualCount_ShouldNotLeftPadText() throws {

        let text = "text"

        let component = Value(text).leftPadded(text.count)

        try XCTAssertComponent(component, returns: text)
    }

    func test_leftPadded_WithWidthAboveCount_ShouldLeftPadText() throws {

        let text = "text"
        let extraWidth = 1
        let character: Character = "*"

        let component = Value(text).leftPadded(text.count + extraWidth, character: character)

        try XCTAssertComponent(component, returns: String(repeating: character, count: extraWidth) + text )
    }

    // rightPadded

    func test_rightPadded_WithWidthBelowCount_ShouldNotRightPadText() throws {

        let text = "text"

        let component = Value(text).rightPadded(text.count - 1)

        try XCTAssertComponent(component, returns: text)
    }

    func test_rightPadded_WithWidthEqualCount_ShouldNotRightPadText() throws {

        let text = "text"

        let component = Value(text).rightPadded(text.count)

        try XCTAssertComponent(component, returns: text)
    }

    func test_rightPadded_WithWidthAboveCount_ShouldRightPadText() throws {

        let text = "text"
        let extraWidth = 1
        let character: Character = "*"

        let component = Value(text).rightPadded(text.count + extraWidth, character: character)

        try XCTAssertComponent(component, returns: text + String(repeating: character, count: extraWidth))
    }

    // trimmed

    func test_trimmed_WithNoMatchingTrailingCharacters_ShouldNotTrimText() throws {

        let text = "text"
        let characterSet = CharacterSet.whitespaces
        XCTAssertEqual(text, text.trimmingCharacters(in: characterSet))

        let component = Value(text).trimmed(characterSet: characterSet)

        try XCTAssertComponent(component, returns: text)

    }

    func test_trimmed_WithMatchingTrailingCharacters_ShouldTrimText() throws {

        let text = " text "
        let characterSet = CharacterSet.whitespaces

        let component = Value(text).trimmed(characterSet: characterSet)

        try XCTAssertComponent(component, returns: text.trimmingCharacters(in: characterSet))
    }

    // MARK: Data

    func test_map_Data_ShouldTransformReceiverData() throws {

        typealias Formatting = Log.ItemFormat.Formatting<Data>

        let data = Data("bbb".utf8)
        let component = Value(data).map { $0.append(contentsOf: "BBB".utf8) }

        var output = Data()
        try component.formatting(.dummy(), &output)

        XCTAssertEqual(output, Data("bbbBBB".utf8))
    }

    // MARK: - Helpers

    private func XCTAssertComponent<F: LogItemFormatComponent>(
        _ component: F,
        item: Log.Item = .dummy(),
        initial: String = "",
        returns expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws where F.Output == String {

        var string = initial
        try component.formatting(item, &string)
        XCTAssertEqual(string, expected, file: file, line: line)
    }
}
