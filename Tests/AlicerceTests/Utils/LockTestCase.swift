import XCTest
@testable import Alicerce

class LockTestCase: XCTestCase {

    func testMake_WithiOS10OrAbove_ShouldReturnAnUnfairLock() {
        let lock = Lock.make()

        XCTAssert(lock is Lock.UnfairLock)
    }
}
