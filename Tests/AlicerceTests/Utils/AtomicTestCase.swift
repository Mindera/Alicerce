//
//  AtomicTestCase.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 13/04/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class AtomicTestCase: XCTestCase {

    private var atomic: Atomic<Int>!
    
    override func setUp() {
        super.setUp()

        atomic = Atomic(0)
    }
    
    override func tearDown() {
        atomic = nil

        super.tearDown()
    }

    func testRead_ShouldReturnValue() {
        XCTAssertEqual(atomic.value, 0)
    }

    func testWrite_ShouldUpdateValue() {
        atomic.value = 1337
        XCTAssertEqual(atomic.value, 1337)
    }

    func testSwap_ShouldSwapValue() {
        XCTAssertEqual(atomic.swap(1337), 0)
        XCTAssertEqual(atomic.value, 1337)
    }

    func testModify_ShouldModifyValue() {
        atomic.modify { $0 += 1337 }
        XCTAssertEqual(atomic.value, 1337)
    }

    func testModify_WithConcurrentAccess_ShouldEnsureThreadSafetyOfCriticalSection() {
        let numWrites = 1000
        let numQueues = 4

        let writeExpectation = expectation(description: "modify")
        writeExpectation.expectedFulfillmentCount = numWrites * numQueues

        let queues: [OperationQueue] = (0..<numQueues).map { _ in
            let q = OperationQueue()
            q.isSuspended = true
            return q
        }

        for _ in 1...numWrites {
            queues.forEach {
                $0.addOperation {
                    self.atomic.modify { $0 += 1 }
                    writeExpectation.fulfill()
                }
            }
        }

        // wait for all work to be scheduled before starting writes
        queues.forEach { $0.isSuspended = false }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(atomic.value, numWrites * numQueues)
    }

    func testWithValue_ShouldPerformAnActionWithTheValue() {
        let result: Bool = atomic.withValue { $0 == 0 }

        XCTAssertTrue(result)
        XCTAssertEqual(atomic.value, 0)
    }
}
