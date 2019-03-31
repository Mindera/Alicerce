import XCTest
@testable import Alicerce

class LoggerTestCase: XCTestCase {

    private var log: MockLogger!
    
    override func setUp() {
        super.setUp()

        log = MockLogger()
    }
    
    override func tearDown() {
        log = nil
        super.tearDown()
    }

    func testVerbose_ShouldInvokeLogWithCorrectLogLevel() {

        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .verbose)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.verbose("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testDebug_ShouldInvokeLogWithCorrectLogLevel() {
        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .debug)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.debug("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testInfo_ShouldInvokeLogWithCorrectLogLevel() {
        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .info)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.info("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testWarning_ShouldInvokeLogWithCorrectLogLevel() {
        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .warning)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.warning("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testError_ShouldInvokeLogWithCorrectLogLevel() {
        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .error)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.error("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testLog_WithLogDestination_ShouldInvokeWriteWithDefaultErrorClosure() {

        enum MockError: Error { case 💣 }

        let log = MockLogDestination()

        log.writeInvokedClosure = { item, errorClosure in
            XCTAssertEqual(item.level, .verbose)
            XCTAssertEqual(item.message, "message")
            XCTAssertEqual(item.file.description, "filename.ext")
            XCTAssertEqual(item.line, 1337)
            XCTAssertEqual(item.function.description, "function")

            errorClosure(MockError.💣)
        }

        log.log(level: .verbose, message: "message", file: "filename.ext", line: 1337, function: "function")
    }
}

private enum MockModule: String, LogModule {
    case 🤖
}

private final class MockLogger: Logger {

    var logInvokedClosure: ((Log.Level, String, StaticString, UInt, StaticString) -> Void)?

    func log(level: Log.Level,
             message: @autoclosure () -> String,
             file: StaticString,
             line: UInt,
             function: StaticString) {
        logInvokedClosure?(level, message(), file, line, function)
    }
}
