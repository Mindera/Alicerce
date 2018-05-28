import XCTest
@testable import Alicerce

class LogTests: XCTestCase {

    fileprivate var log: Log!

    override func setUp() {
        super.setUp()

        log = Log()
    }

    override func tearDown() {
        log = nil

        super.tearDown()
    }

    func testRegister_WithUniqueIDs_ShouldSucceed() {

        let destination1 = Log.ConsoleLogDestination()
        let destination2 = Log.FileLogDestination(fileURL: URL(string: "https://www.google.com")!)
        let destination3 = Log.FileLogDestination(fileURL: URL(string: "https://www.amazon.com")!)

        do {
            try log.register(destination1)
            XCTAssertEqual(log.destinations.value.count, 1)
            try log.register(destination2)
            XCTAssertEqual(log.destinations.value.count, 2)
            try log.register(destination3)
            XCTAssertEqual(log.destinations.value.count, 3)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testRegister_WithDuplicateIDs_ShouldFail() {

        let destination1 = Log.ConsoleLogDestination()

        do {
            try log.register(destination1)
            XCTAssertEqual(log.destinations.value.count, 1)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        do {
            try log.register(destination1)
        } catch Log.Error.duplicateDestination(let id) {
            XCTAssertEqual(id, destination1.id)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testUnregister_WithExistingID_ShouldSucceed() {

        let destination1 = Log.ConsoleLogDestination()

        do {
            try log.register(destination1)
            XCTAssertEqual(log.destinations.value.count, 1)
            try log.unregister(destination1)
            XCTAssertEqual(log.destinations.value.count, 0)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testUnregister_WithNonExistingIDs_ShouldFail() {

        let destination1 = Log.ConsoleLogDestination()

        do {
            XCTAssertEqual(log.destinations.value.count, 0)
            try log.unregister(destination1)
        } catch Log.Error.inexistentDestination(let id) {
            XCTAssertEqual(id, destination1.id)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testErrorLoggingLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .error, formatter: formatter)

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

        let expected = "error message"
        XCTAssertEqual(destination.output, expected)
        XCTAssertEqual(destination.output.split(separator: "\n").count, 1)
    }

    func testWarningLoggingLevels() {

        // preparation of the test subject

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .warning, formatter: formatter)

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

        let expected = "warning message\nerror message"
        XCTAssertEqual(destination.output, expected)
        XCTAssertEqual(destination.output.split(separator: "\n").count, 2)
    }

    func testInfoLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .info, formatter: formatter)

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

        let expected = "info message\nwarning message\nerror message"
        XCTAssertEqual(destination.output, expected)
        XCTAssertEqual(destination.output.split(separator: "\n").count, 3)
    }

    func testDebugLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
        let destination = Log.StringLogDestination(minLevel: .debug, formatter: formatter)

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

        let expected = "debug message\ninfo message\nwarning message\nerror message"
        XCTAssertEqual(destination.output, expected)
        XCTAssertEqual(destination.output.split(separator: "\n").count, 4)
    }

    func testVerboseLoggingLevels() {

        let formatter = Log.StringLogItemFormatter(formatString: "$M")
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

        let expected = "verbose message\ndebug message\ninfo message\nwarning message\nerror message"
        XCTAssertEqual(destination.output, expected)
        XCTAssertEqual(destination.output.split(separator: "\n").count, 5)
    }
}
