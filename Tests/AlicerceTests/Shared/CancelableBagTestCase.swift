import XCTest
@testable import Alicerce

class CancelableBagTestCase: XCTestCase {

    private var cancelable: CancelableBag!

    override func setUp() {
        super.setUp()

        cancelable = CancelableBag()
    }

    override func tearDown() {
        cancelable = nil

        super.tearDown()
    }

    // init

    func testInit_WithMultipleCancelables_ShouldSucceed() {
        cancelable = CancelableBag([MockCancelable(), MockCancelable()])
    }

    // isCancelled

    func testIsCancelled_WithNotCancelledCancelableBag_ShouldReturnFalse() {
        XCTAssertFalse(cancelable.isCancelled)
    }

    func testIsCancelled_WithCancelledCancelableBag_ShouldReturnTrue() {
        XCTAssertFalse(cancelable.isCancelled)
        cancelable.cancel()
        XCTAssertTrue(cancelable.isCancelled)
    }

    // add

    func testAdd_WithNotCancelledCancelledBag_ShouldAddCancelableToBag() {
        let expectation = self.expectation(description: "add")
        defer { waitForExpectations(timeout: 1) }

        XCTAssertFalse(cancelable.isCancelled)

        let mockCancelable = MockCancelable()

        cancelable.add(cancelable: mockCancelable)

        mockCancelable.mockCancelClosure = {
            expectation.fulfill() // ensure it has been added
        }

        cancelable.cancel()
    }

    func testAdd_WithCancelledCancelledBag_ShouldNotAddCancelableToBagAndCancelCancellable() {
        let expectation = self.expectation(description: "add")
        defer { waitForExpectations(timeout: 1) }

        XCTAssertFalse(cancelable.isCancelled)
        cancelable.cancel()
        XCTAssertTrue(cancelable.isCancelled)

        let mockCancelable = MockCancelable()
        mockCancelable.mockCancelClosure = {
            expectation.fulfill() // ensure it was cancelled
        }

        cancelable.add(cancelable: mockCancelable)
    }

    // cancel

    func testCancel_WithNotCancelledCancelledBag_ShouldCancelAllStoredCancelable() {
        let expectation = self.expectation(description: "cancel")
        expectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        XCTAssertFalse(cancelable.isCancelled)

        let mockCancelableA = MockCancelable()
        let mockCancelableB = MockCancelable()

        cancelable = CancelableBag([mockCancelableA, mockCancelableB])

        mockCancelableA.mockCancelClosure = {
            expectation.fulfill() // ensure it was cancelled
        }
        mockCancelableB.mockCancelClosure = {
            expectation.fulfill() // ensure it was cancelled
        }

        cancelable.cancel()
    }

    func testCancel_WithCancelledCancelledBag_ShouldNotCancelAnyStoredCancelable() {
        XCTAssertFalse(cancelable.isCancelled)

        let mockCancelableA = MockCancelable()
        let mockCancelableB = MockCancelable()

        cancelable = CancelableBag([mockCancelableA, mockCancelableB])

        cancelable.cancel()
        XCTAssertTrue(cancelable.isCancelled)

        mockCancelableA.mockCancelClosure = {
            XCTFail("😱: unexpected cancel invoked!")
        }
        mockCancelableB.mockCancelClosure = {
            XCTFail("😱: unexpected cancel invoked!")
        }

        cancelable.cancel()
    }
}
