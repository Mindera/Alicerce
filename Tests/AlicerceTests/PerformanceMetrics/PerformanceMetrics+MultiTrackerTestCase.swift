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

    // init

    func testInit_WithResultBuilder_ShouldInstantiateCorrectTrackers() {

        let subTracker1 = SubTracker()
        let subTracker2 = SubTracker()
        let subTracker3 = SubTracker()
        let subTrackerOpt = SubTracker()
        let subTrackerTrue = SubTracker()
        let subTrackerFalse = SubTracker()
        let subTrackerArray = (1...3).map { _ in SubTracker() }
        let subTrackerAvailable = SubTracker()

        let optVar: Bool? = true
        let optNil: Bool? = nil
        let trueVar = true
        let falseVar = false

        let tracker = MultiTracker {
            subTracker1
            subTracker2

            [subTracker3]

            if let _ = optVar { subTrackerOpt }
            if let _ = optNil { subTrackerOpt }

            if trueVar {
                subTrackerTrue
            } else {
                subTrackerFalse
            }

            if falseVar {
                subTrackerTrue
            } else {
                subTrackerFalse
            }

            for tracker in subTrackerArray { tracker }

            if #available(iOS 1.337, *) { subTrackerAvailable }
        }

        XCTAssertDumpsEqual(
            tracker.trackers,
            [
                subTracker1,
                subTracker2,
                subTracker3,
                subTrackerOpt,
                subTrackerTrue,
                subTrackerFalse
            ]
            + subTrackerArray
            + [subTrackerAvailable]
        )
    }

    // start

    func testStart_ShouldInvokeStartOnAllSubTrackers() {
        let expectationA = expectation(description: "startA")
        let expectationB = expectation(description: "startB")
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
        let expectationA = expectation(description: "startA")
        expectationA.expectedFulfillmentCount = 2
        let expectationB = expectation(description: "startB")
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
        let expectationA = expectation(description: "stopA")
        let expectationB = expectation(description: "stopB")
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
        let startA = expectation(description: "startA")
        let startB = expectation(description: "startB")
        let stopA = expectation(description: "stopA")
        let stopB = expectation(description: "stopB")
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
        let startA = expectation(description: "startA")
        let startB = expectation(description: "startB")
        let stopA = expectation(description: "stopA")
        let stopB = expectation(description: "stopB")
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
