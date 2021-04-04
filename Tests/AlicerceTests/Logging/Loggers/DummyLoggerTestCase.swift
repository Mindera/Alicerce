import XCTest
@testable import Alicerce

class DummyLoggerTestCase: XCTestCase {

    func testLog_withEvaluateMessageClosuresSetToTrue_ShouldEvaluateMessage() {
        
        let messageExpectation = expectation(description: "message")
        defer { waitForExpectations(timeout: 1) }

        let log = Log.DummyLogger(evaluateMessageClosures: true)

        log.log(
            level: .verbose,
            message: "message \(messageExpectation.fulfill()))",
            file: "filename.ext",
            line: 1337,
            function: "function"
        )
    }

    func testLog_WithEvaluateMessageClosuresSetToFalse_ShouldNotEvaluateMessage() {

        let log = Log.DummyLogger(evaluateMessageClosures: false)

        log.log(
            level: .verbose,
            message: "\(XCTFail("💥"))",
            file: "filename.ext",
            line: 1337,
            function: "function"
        )
    }
}
