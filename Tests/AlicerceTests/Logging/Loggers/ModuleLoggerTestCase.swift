import XCTest
@testable import Alicerce

class ModuleLoggerTestCase: XCTestCase {

    private var log: MockModuleLogger!

    override func setUp() {
        super.setUp()

        log = MockModuleLogger()
    }

    override func tearDown() {
        log = nil
        super.tearDown()
    }

    // module

    func testVerbose_WithNonNilModule_ShouldInvokeLogWithCorrectLogLevel() {

        log.moduleLogInvokedClosure = { module, level, message, file, line, function in
            XCTAssertEqual(module, MockModule.🤖)
            XCTAssertEqual(level, .verbose)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.verbose(.🤖, "message", file: "filename.ext", line: 1337, function: "function")
    }

    func testDebug_WithNonNilModule_ShouldInvokeLogWithCorrectLogLevel() {
        log.moduleLogInvokedClosure = { module, level, message, file, line, function in
            XCTAssertEqual(module, MockModule.🤖)
            XCTAssertEqual(level, .debug)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.debug(.🤖, "message", file: "filename.ext", line: 1337, function: "function")
    }

    func testInfo_WithNonNilModule_ShouldInvokeLogWithCorrectLogLevel() {
        log.moduleLogInvokedClosure = { module, level, message, file, line, function in
            XCTAssertEqual(module, MockModule.🤖)
            XCTAssertEqual(level, .info)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.info(.🤖, "message", file: "filename.ext", line: 1337, function: "function")
    }

    func testWarning_WithNonNilModule_ShouldInvokeLogWithCorrectLogLevel() {
        log.moduleLogInvokedClosure = { module, level, message, file, line, function in
            XCTAssertEqual(module, MockModule.🤖)
            XCTAssertEqual(level, .warning)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.warning(.🤖, "message", file: "filename.ext", line: 1337, function: "function")
    }

    func testError_WithNonNilModule_ShouldInvokeLogWithCorrectLogLevel() {
        log.moduleLogInvokedClosure = { module, level, message, file, line, function in
            XCTAssertEqual(module, MockModule.🤖)
            XCTAssertEqual(level, .error)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.error(.🤖, "message", file: "filename.ext", line: 1337, function: "function")
    }

    // no module

    func testVerbose_WithNilModule_ShouldInvokeLogWithCorrectLogLevel() {

        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .verbose)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.verbose("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testDebug_WithNilModule_ShouldInvokeLogWithCorrectLogLevel() {
        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .debug)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.debug("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testInfo_WithNilModule_ShouldInvokeLogWithCorrectLogLevel() {
        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .info)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.info("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testWarning_WithNilModule_ShouldInvokeLogWithCorrectLogLevel() {
        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .warning)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.warning("message", file: "filename.ext", line: 1337, function: "function")
    }

    func testError_WithNilModule_ShouldInvokeLogWithCorrectLogLevel() {
        log.logInvokedClosure = { level, message, file, line, function in
            XCTAssertEqual(level, .error)
            XCTAssertEqual(message, "message")
            XCTAssertEqual(file.description, "filename.ext")
            XCTAssertEqual(line, 1337)
            XCTAssertEqual(function.description, "function")
        }

        log.error("message", file: "filename.ext", line: 1337, function: "function")
    }
}

private enum MockModule: String, LogModule {
    case 🤖
}

private final class MockModuleLogger: ModuleLogger {

    var logInvokedClosure: ((Log.Level, String, StaticString, UInt, StaticString) -> Void)?
    var moduleLogInvokedClosure: ((Module, Log.Level, String, StaticString, UInt, StaticString) -> Void)?

    typealias Module = MockModule

    func log(level: Log.Level,
             message: @autoclosure () -> String,
             file: StaticString,
             line: UInt,
             function: StaticString) {
        logInvokedClosure?(level, message(), file, line, function)
    }

    func log(module: Module,
             level: Log.Level,
             message: @autoclosure () -> String,
             file: StaticString,
             line: UInt,
             function: StaticString) {
        moduleLogInvokedClosure?(module, level, message(), file, line, function)
    }

    // MARK: - Modules

    func registerModule(_ module: Module, minLevel: Log.Level) throws {}
    func unregisterModule(_ module: Module) throws {}
}
