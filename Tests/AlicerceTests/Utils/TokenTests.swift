import XCTest
@testable import Alicerce

class TokenTests: XCTestCase {

    func testNext_ShouldGenerateUniqueTokens() {

        let tokenizer = Tokenizer<()>()

        let tokens = (0..<100).map { _ in tokenizer.next }
        let set = Set(tokens)

        XCTAssertEqual(tokens.count, set.count)
    }

    func testNext_ShouldGenerateTheSameSequenceWithDifferentTokenizers() {

        let tokenizer1 = Tokenizer<Int>()
        let tokenizer2 = Tokenizer<Int>()

        let tokens1 = (0..<100).map { _ in tokenizer1.next }
        let tokens2 = (0..<100).map { _ in tokenizer2.next }

        XCTAssertEqual(tokens1, tokens2)
    }

    func testNext_ShouldHandleConcurrentAccesses() {

        let count: (accesses: Int, queues: Int) = (100, 4)

        let queues: [OperationQueue] = (0..<count.queues).map { _ in
            let queue = OperationQueue()
            queue.isSuspended = true
            return queue
        }

        let tokenizer = Tokenizer<Int>()
        let tokens = Atomic<[Token<Int>]>([])

        let expectation = self.expectation(description: "token")
        expectation.expectedFulfillmentCount = count.accesses * count.queues

        (0..<count.accesses).forEach { _ in
            queues.forEach {
                $0.addOperation {
                    let token = tokenizer.next
                    tokens.modify { $0.append(token) }
                    expectation.fulfill()
                }
            }
        }

        queues.forEach { $0.isSuspended = false }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(tokens.value.count, count.accesses * count.queues)
        XCTAssertEqual(Set(tokens.value).count, tokens.value.count)
    }
}
