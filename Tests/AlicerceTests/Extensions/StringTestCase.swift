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
    
}
