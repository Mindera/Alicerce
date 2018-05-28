import XCTest
@testable import Alicerce

class ConsoleLogDestinationsTests: XCTestCase {

    fileprivate var log: Log!
    fileprivate var queue: Log.Queue!
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func setUp() {
        super.setUp()

        log = Log()
        queue = Log.Queue(label: "ConsoleLogDestinationsTests")
    }

    override func tearDown() {
        log = nil
        queue = nil

        super.tearDown()
    }

    func testConsoleLogDestination() {

        let expectation = self.expectation(description: "ConsoleLogDestinationExpectationWrittenLines")
        expectation.expectedFulfillmentCount = 5

        let verboseExpectation = self.expectation(description: "ConsoleLogDestinationExpectationVerboseLevel")
        let debugExpectation = self.expectation(description: "ConsoleLogDestinationExpectationDebugLevel")
        let infoExpectation = self.expectation(description: "ConsoleLogDestinationExpectationInfoLevel")
        let warningExpectation = self.expectation(description: "ConsoleLogDestinationExpectationWarningLevel")
        let errorExpectation = self.expectation(description: "ConsoleLogDestinationExpectationErrorLevel")

        defer {
            waitForExpectations(timeout: expectationTimeout, handler: expectationHandler)
        }

        // preparation of the test subject

        let outputClosure: Log.ConsoleLogDestination.OutputClosure = {
            level, _ in

            switch level {
            case .verbose: verboseExpectation.fulfill()
            case .debug: debugExpectation.fulfill()
            case .info: infoExpectation.fulfill()
            case .warning: warningExpectation.fulfill()
            case .error: errorExpectation.fulfill()
            }

            expectation.fulfill()
        }

        let destination = Log.ConsoleLogDestination(minLevel: .verbose,
                                                    queue: queue,
                                                    outputClosure: outputClosure)

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
    }
}
