import XCTest
@testable import Alicerce

class URLSessionTask_CancelableTestCase: XCTestCase {

    func testIsCancelled_WithCancellingTask_ShouldReturnTrue() {
        let task = MockURLSessionDataTask()

        task.mockState = .canceling
        XCTAssertTrue(task.isCancelled)
    }

    func testIsCancelled_WithNonCancellingTask_ShouldReturnFalse() {
        let task = MockURLSessionDataTask()

        task.mockState = .completed
        XCTAssertFalse(task.isCancelled)

        task.mockState = .running
        XCTAssertFalse(task.isCancelled)

        task.mockState = .suspended
        XCTAssertFalse(task.isCancelled)
    }
}
