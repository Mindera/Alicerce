import XCTest
@testable import Alicerce

class DummyCancelableTestCase: XCTestCase {

    func testIsCancelled_ShouldAlwaysReturnFalse() {
        let cancellable = DummyCancelable()

        XCTAssertFalse(cancellable.isCancelled)
    }

    func testCancel_ShouldNotDoAnything() {
        let cancellable = DummyCancelable()

        XCTAssertFalse(cancellable.isCancelled)
        cancellable.cancel()
        XCTAssertFalse(cancellable.isCancelled)
    }
}
