import XCTest
@testable import Alicerce

class LockTestCase: XCTestCase {

    func testMake_WithiOS16OrAbove_ShouldReturnAnAllocatedUnfairLock() {
        let lock = Lock.make()

        if #available(iOS 16, *) {
            XCTAssert(lock is Lock.AllocatedUnfairLock)
        } else {
            XCTAssert(lock is Lock.UnfairLock)
        }
    }
}
