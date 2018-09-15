import XCTest

class ThreadTestCase: XCTestCase {

    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    func testBackgroundThreadWithoutName() {

        let expectation = self.expectation(description: "testBackgroundThreadWithoutName")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let thread = Thread() {

            XCTAssertEqual(Thread.currentName, String(format: "%p", Thread.current))
            expectation.fulfill()
        }

        thread.qualityOfService = .utility
        thread.start()
    }

    func testBackgroundThreadWithName() {

        let expectation = self.expectation(description: "testBackgroundThreadWithName")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let thread = Thread() {

            XCTAssertEqual(Thread.currentName, "com.mindera.alicerce.threadtests.background")
            expectation.fulfill()
        }

        thread.qualityOfService = .utility
        thread.name = "com.mindera.alicerce.threadtests.background"
        thread.start()
    }

    func testMainThread() {

        XCTAssertEqual(Thread.currentName, "main-thread")
    }
}
