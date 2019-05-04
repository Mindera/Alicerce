import XCTest

class DispatchQueueTestCase: XCTestCase {

    func testCurrentLabel_WithCustomQueue_ShouldReturnCorrectName() {

        let label = "com.alicerce.custom-queue"
        let queue = DispatchQueue(label: label)

        queue.sync {
            XCTAssertEqual(DispatchQueue.currentLabel, label)
        }
    }

    func testCurrentLabel_WithMainQueue_ShouldReturnCorrectName() {
        let expectation = self.expectation(description: "main queue")
        defer { waitForExpectations(timeout: 1) }

        DispatchQueue.main.async {
            XCTAssertEqual(DispatchQueue.currentLabel, DispatchQueue.main.label)
            expectation.fulfill()
        }
    }
    
}
