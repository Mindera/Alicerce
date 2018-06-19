import XCTest
@testable import Alicerce

class ColoredLevelTests: XCTestCase {

    fileprivate var log: Log!

    override func setUp() {
        super.setUp()

        log = Log()
    }

    override func tearDown() {
        log = nil

        super.tearDown()
    }

    func testFileLogDestinationDefaultColoredLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$C$M")
        let destination = Log.StringLogDestination(minLevel: .verbose, formatter: formatter)

        // execute test

        do {
            try log.register(destination)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        let expected = "📓verbose message\n📗debug message\n📘info message\n📒warning message\n📕error message"
        XCTAssertEqual(destination.output, expected)
    }

    func testFileLogDestinationBashColoredLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$C$M",
                                                   levelFormatter: Log.BashLogItemLevelFormatter())
        let destination = Log.StringLogDestination(minLevel: .verbose, formatter: formatter)

        // execute test

        do {
            try log.register(destination)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        let expected = "\u{1B}[38;5;251mverbose message\n\u{1B}[38;5;35mdebug message\n\u{1B}[38;5;38minfo message\n\u{1B}[38;5;178mwarning message\n\u{1B}[38;5;197merror message"
        XCTAssertEqual(destination.output, expected)
    }
}
