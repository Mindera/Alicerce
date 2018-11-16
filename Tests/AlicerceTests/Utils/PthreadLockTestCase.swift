import XCTest
@testable import Alicerce

class PthreadLockTestCase: XCTestCase {

    private var lock: Lock.PthreadLock!
    private var queue: DispatchQueue!

    override func setUp() {
        super.setUp()

        lock = Lock.PthreadLock()
        queue = DispatchQueue(label: "testQueue", qos: .default)
    }

    override func tearDown() {
        lock = nil
        queue = nil

        super.tearDown()
    }

    func testLock_ShouldLock() {
        let lockExpectation = expectation(description: "lock")

        queue.asyncAfter(deadline: .now() + .milliseconds(10)) {
            XCTAssertFalse(self.lock.try())
            lockExpectation.fulfill()
        }

        lock.lock()

        waitForExpectations(timeout: 1)

        lock.unlock()
    }

    func testUnlock_ShouldUnlock() {
        let tryExpectation = expectation(description: "try")
        let lockExpectation = expectation(description: "lock")
        let unlockExpectation = expectation(description: "unlock")

        let sem = DispatchSemaphore(value: 0)

        queue.asyncAfter(deadline: .now() + .milliseconds(10)) {
            XCTAssertFalse(self.lock.try())
            tryExpectation.fulfill()

            self.lock.lock() // should block until unlocked
            lockExpectation.fulfill()

            sem.wait()

            self.lock.unlock()
            unlockExpectation.fulfill()
        }

        lock.lock()

        wait(for: [tryExpectation], timeout: 1)

        lock.unlock()

        wait(for: [lockExpectation], timeout: 1)

        XCTAssertFalse(self.lock.try())
        sem.signal()

        wait(for: [unlockExpectation], timeout: 1)
    }

    func testTry_WithLockedLock_ShouldReturnFalse() {
        let tryLockExpectation = expectation(description: "try")

        queue.asyncAfter(deadline: .now() + .milliseconds(10)) {
            XCTAssertFalse(self.lock.try())
            tryLockExpectation.fulfill()
        }

        lock.lock()

        waitForExpectations(timeout: 1)

        lock.unlock()
    }

    func testTry_WithUnlockedLock_ShouldReturnTrueAndLock() {
        let tryLockExpectation = expectation(description: "try")

        queue.asyncAfter(deadline: .now() + .milliseconds(10)) {
            XCTAssertFalse(self.lock.try())
            tryLockExpectation.fulfill()
        }

        XCTAssertTrue(self.lock.try())

        waitForExpectations(timeout: 1)

        lock.unlock()
    }

    func testLockUnlock_WithConcurrentAccess_ShouldEnsureThreadSafetyOfCriticalSection() {
        let numWrites = 1000
        let numQueues = 4

        let writeExpectation = expectation(description: "write")
        writeExpectation.expectedFulfillmentCount = numWrites * numQueues

        let queues: [OperationQueue] = (0..<numQueues).map { _ in
            let q = OperationQueue()
            q.isSuspended = true
            return q
        }

        let box = VarBox(0)

        for _ in 1...numWrites {
            queues.forEach {
                $0.addOperation {
                    self.lock.lock()
                    box.value += 1
                    self.lock.unlock()
                    writeExpectation.fulfill()
                }
            }
        }

        // wait for all work to be scheduled before starting writes
        queues.forEach { $0.isSuspended = false }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(box.value, numWrites * numQueues)
    }
}
