import XCTest
import Alicerce

final class PerformanceMetrics_MultiTrackerTestCase: XCTestCase {

    typealias MultiTracker = PerformanceMetrics.MultiTracker
    typealias SubTracker = MockPerformanceMetricsTracker

    private var tracker: MultiTracker!
    private var subTrackerA: SubTracker!
    private var subTrackerB: SubTracker!

    override func setUp() {
        super.setUp()

        subTrackerA = SubTracker()
        subTrackerB = SubTracker()
        tracker = MultiTracker(trackers: [subTrackerA, subTrackerB])
    }

    override func tearDown() {
        tracker = nil
        subTrackerA = nil
        subTrackerB = nil

        super.tearDown()
    }

    // start

    func testStart_ShouldInvokeStartOnAllSubTrackers() {
        let expectationA = self.expectation(description: "startA")
        let expectationB = self.expectation(description: "startB")
        defer { waitForExpectations(timeout: 1) }

        let testIdentifier: PerformanceMetrics.Identifier = "test"

        subTrackerA.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            expectationA.fulfill()
        }

        subTrackerB.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            expectationB.fulfill()
        }

        let _ = tracker.start(with: testIdentifier)
    }

    func testStart_WithMultipleInvocationsForTheSameIdentifier_ShouldReturnDifferentTokens() {
        let expectationA = self.expectation(description: "startA")
        expectationA.expectedFulfillmentCount = 2
        let expectationB = self.expectation(description: "startB")
        expectationB.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let testIdentifier: PerformanceMetrics.Identifier = "test"

        subTrackerA.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            expectationA.fulfill()
        }

        subTrackerB.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            expectationB.fulfill()
        }

        let tokenA = tracker.start(with: testIdentifier)
        let tokenB = tracker.start(with: testIdentifier)

        XCTAssertNotEqual(tokenA, tokenB)
    }

    // stop

    func testStop_ShouldInvokeStopOnAllSubTrackers() {
        let expectationA = self.expectation(description: "stopA")
        let expectationB = self.expectation(description: "stopB")
        defer { waitForExpectations(timeout: 1) }

        let testToken = tracker.start(with: "test")

        let testMetadata: PerformanceMetrics.Metadata = [ "📊" : 1337, "π" : Double.pi]

        subTrackerA.stopInvoked = { _, metadata in
            XCTAssertDumpsEqual(metadata, testMetadata)
            expectationA.fulfill()
        }

        subTrackerB.stopInvoked = { _, metadata in
            XCTAssertDumpsEqual(metadata, testMetadata)
            expectationB.fulfill()
        }

        tracker.stop(with: testToken, metadata: testMetadata)
    }

    // measure (synchronous stop)

    func testMeasure_WithSynchronousStop_ShouldInvokeStartAndStopOnAllSubTrackers() {
        let startA = self.expectation(description: "startA")
        let startB = self.expectation(description: "startB")
        let stopA = self.expectation(description: "stopA")
        let stopB = self.expectation(description: "stopB")
        defer { waitForExpectations(timeout: 1) }

        let testIdentifier: PerformanceMetrics.Identifier = "test"
        let testMetadata: PerformanceMetrics.Metadata = [ "📊" : 1337, "π" : Double.pi]

        subTrackerA.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            startA.fulfill()
        }

        subTrackerB.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            startB.fulfill()
        }

        subTrackerA.stopInvoked = { _, metadata in
            XCTAssertDumpsEqual(metadata, testMetadata)
            stopA.fulfill()
        }

        subTrackerB.stopInvoked = { _, metadata in
            XCTAssertDumpsEqual(metadata, testMetadata)
            stopB.fulfill()
        }

        tracker.measure(with: testIdentifier, metadata: testMetadata) {}
    }

    // measure (with stop closure)

    func testMeasure_WithStop_ShouldInvokeStartAndStopOnAllSubTrackers() {
        let startA = self.expectation(description: "startA")
        let startB = self.expectation(description: "startB")
        let stopA = self.expectation(description: "stopA")
        let stopB = self.expectation(description: "stopB")
        defer { waitForExpectations(timeout: 1) }

        let testIdentifier: PerformanceMetrics.Identifier = "test"
        let testMetadata: PerformanceMetrics.Metadata = [ "📊" : 1337, "π" : Double.pi]

        subTrackerA.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            startA.fulfill()
        }

        subTrackerB.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            startB.fulfill()
        }

        subTrackerA.stopInvoked = { _, metadata in
            XCTAssertDumpsEqual(metadata, testMetadata)
            stopA.fulfill()
        }

        subTrackerB.stopInvoked = { _, metadata in
            XCTAssertDumpsEqual(metadata, testMetadata)
            stopB.fulfill()
        }

        tracker.measure(with: testIdentifier) { end in end(testMetadata) }
    }

}
