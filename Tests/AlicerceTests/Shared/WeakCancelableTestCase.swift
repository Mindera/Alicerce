import XCTest
@testable import Alicerce

class WeakCancelableTestCase: XCTestCase {

    private var mockCancelable: MockCancelable!
    private var cancelable: WeakCancelable!

    override func setUp() {
        super.setUp()

        mockCancelable = MockCancelable()
        cancelable = WeakCancelable(mockCancelable)
    }

    override func tearDown() {
        mockCancelable = nil
        cancelable = nil

        super.tearDown()
    }

    // isCancelled

    func testIsCancelled_WithNotCancelledWrappedCancelable_ShouldReturnFalse() {
        XCTAssertFalse(mockCancelable.isCancelled)
        XCTAssertFalse(cancelable.isCancelled)
    }

    func testIsCancelled_WithCancelledWrappedCancelable_ShouldReturnTrue() {
        mockCancelable.mockIsCancelled = true

        XCTAssertTrue(mockCancelable.isCancelled)
        XCTAssertTrue(cancelable.isCancelled)
    }

    func testIsCancelled_WithDeinitedWrappedCancelable_ShouldReturnTrue() {
        mockCancelable = MockCancelable()

        XCTAssertTrue(cancelable.isCancelled)
    }

    // cancel

    func testCancel_WithNotCancelledWrappedCancelled_ShouldCancel() {
        let expectation = self.expectation(description: "cancel")
        defer { waitForExpectations(timeout: 1) }

        mockCancelable.mockIsCancelled = false
        mockCancelable.mockCancelClosure = {
            expectation.fulfill()
        }

        XCTAssertFalse(cancelable.isCancelled)
        cancelable.cancel()
    }

    func testCancel_WithCancelledWrappedCancelled_ShouldNotCancel() {

        mockCancelable.mockIsCancelled = true
        mockCancelable.mockCancelClosure = {
            XCTFail("😱: unexpected cancel invoked!")
        }

        XCTAssertTrue(cancelable.isCancelled)
        cancelable.cancel()
    }

    func testCancel_WithDeinitedWrappedCancelled_ShouldNotCancel() {
        mockCancelable = MockCancelable()

        XCTAssertTrue(cancelable.isCancelled)
        cancelable.cancel()
        XCTAssertTrue(cancelable.isCancelled)
    }

}
