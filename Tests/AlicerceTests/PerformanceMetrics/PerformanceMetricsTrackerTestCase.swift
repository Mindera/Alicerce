import XCTest
@testable import Alicerce

final class PerformanceMetricsTestCase: XCTestCase {

    private typealias Tracker = MockStartStopPerformanceMetricsTracker

    private var tracker: Tracker!

    override func setUp() {
        super.setUp()

        tracker = Tracker()
    }

    override func tearDown() {
        tracker = nil

        super.tearDown()
    }

    // measure (synchronous stop)

    func testMeasure_WithSynchronousStop_ShouldInvokeStartAndStopOnAllSubTrackers() {
        let start = self.expectation(description: "start")
        let stop = self.expectation(description: "stop")
        defer { waitForExpectations(timeout: 1) }

        let testIdentifier: PerformanceMetrics.Identifier = "test"
        let testMetadata: PerformanceMetrics.Metadata = [ "📊" : 1337, "π" : Double.pi]

        tracker.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            start.fulfill()
        }

        tracker.stopInvoked = { _, metadata in
            assertDumpsEqual(metadata, testMetadata)
            stop.fulfill()
        }

        tracker.measure(with: testIdentifier, metadata: testMetadata) {}
    }

    // measure (with stop closure)

    func testMeasure_WithStop_ShouldInvokeStartAndStopOnAllSubTrackers() {
        let start = self.expectation(description: "start")
        let stop = self.expectation(description: "stop")
        defer { waitForExpectations(timeout: 1) }

        let testIdentifier: PerformanceMetrics.Identifier = "test"
        let testMetadata: PerformanceMetrics.Metadata = [ "📊" : 1337, "π" : Double.pi]

        tracker.startInvoked = {
            XCTAssertEqual($0, testIdentifier)
            start.fulfill()
        }

        tracker.stopInvoked = { _, metadata in
            assertDumpsEqual(metadata, testMetadata)
            stop.fulfill()
        }

        tracker.measure(with: testIdentifier) { end in end(testMetadata) }
    }

}

private final class MockStartStopPerformanceMetricsTracker: PerformanceMetricsTracker {

    var startInvoked: ((Identifier) -> Void)?
    var stopInvoked: ((Token<Tag>, Metadata?) -> Void)?

    let tokenizer = Tokenizer<Tag>()

    func start(with identifier: Identifier) -> Token<Tag> {
        startInvoked?(identifier)
        return tokenizer.next
    }

    func stop(with token: Token<Tag>, metadata: Metadata?) {
        stopInvoked?(token, metadata)
    }
}
