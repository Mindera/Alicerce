import XCTest
@testable import Alicerce

final class MultiTrackerTestCase: XCTestCase {

    enum MockState {
        case screen(name: String)
        case userLoggedIn(email: String)
        case userLoggedOut
    }

    enum MockAction {
        case 🔨
        case 🔎(searchTerm: String)
    }

    enum MockParameterKey: String, AnalyticsParameterKey {
        case language
        case date
    }

    typealias MultiTracker = Analytics.MultiTracker<MockState, MockAction, MockParameterKey>
    typealias MockSubTracker = MockAnalyticsTracker<MockState, MockAction, MockParameterKey>

    private var tracker: MultiTracker!

    override func setUp() {
        super.setUp()

        tracker = MultiTracker()
    }

    override func tearDown() {
        tracker = nil

        super.tearDown()
    }

    // register

    func testRegister_WithUniqueIDs_ShouldSucceed() {

        let subTracker1 = MockSubTracker(id: "1")
        let subTracker2 = MockSubTracker(id: "2")

        do {
            try tracker.register(subTracker1)
            XCTAssertEqual(tracker.subTrackers.count, 1)
            try tracker.register(subTracker2)
            XCTAssertEqual(tracker.subTrackers.count, 2)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testRegister_WithDuplicateIDs_ShouldFail() {

        let subTracker = MockSubTracker()

        do {
            try tracker.register(subTracker)
            XCTAssertEqual(tracker.subTrackers.count, 1)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        do {
            try tracker.register(subTracker)
        } catch Analytics.MultiTrackerError.duplicateTracker(let id) {
            XCTAssertEqual(id, subTracker.id)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    // unregister

    func testUnregister_WithExistingID_ShouldSucceed() {

        let subTracker = MockSubTracker()

        do {
            try tracker.register(subTracker)
            XCTAssertEqual(tracker.subTrackers.count, 1)
            try tracker.unregister(subTracker)
            XCTAssertEqual(tracker.subTrackers.count, 0)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testUnregister_WithNonExistingIDs_ShouldFail() {

        let subTracker = MockSubTracker()

        do {
            XCTAssertEqual(tracker.subTrackers.count, 0)
            try tracker.unregister(subTracker)
        } catch Analytics.MultiTrackerError.inexistentTracker(let id) {
            XCTAssertEqual(id, subTracker.id)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    // track

    func testTrack_WithUniqueIDs_ShouldSucceed() {

        let subTracker1 = MockSubTracker(id: "1")
        let subTracker2 = MockSubTracker(id: "2")

        do {
            try tracker.register(subTracker1)
            XCTAssertEqual(tracker.subTrackers.count, 1)
            try tracker.register(subTracker2)
            XCTAssertEqual(tracker.subTrackers.count, 2)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testTrack_WithRegisteredSubTrackersAndActionEvent_ShouldCallTrackOnAllSubTrackers() {
        let trackExpectation = self.expectation(description: "track")
        trackExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let subTracker1 = MockSubTracker(id: "1")
        let subTracker2 = MockSubTracker(id: "2")

        do {
            try tracker.register(subTracker1)
            try tracker.register(subTracker2)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let event = MultiTracker.Event.action(.🔨, [.language : "🇵🇹", .date : Date()])

        subTracker1.trackInvokedClosure = { trackEvent in
            assertDumpsEqual(trackEvent, event)
            trackExpectation.fulfill()
        }

        subTracker2.trackInvokedClosure = { trackEvent in
            assertDumpsEqual(trackEvent, event)
            trackExpectation.fulfill()
        }

        tracker.track(event)
    }

    func testTrack_WithRegisteredSubTrackersAndStateEvent_ShouldCallTrackOnAllSubTrackers() {
        let trackExpectation = self.expectation(description: "track")
        trackExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let subTracker1 = MockSubTracker(id: "1")
        let subTracker2 = MockSubTracker(id: "2")

        do {
            try tracker.register(subTracker1)
            try tracker.register(subTracker2)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let event = MultiTracker.Event.state(.screen(name: "🖼"), [.language : "🇵🇹", .date : Date()])

        subTracker1.trackInvokedClosure = { trackEvent in
            assertDumpsEqual(trackEvent, event)
            trackExpectation.fulfill()
        }

        subTracker2.trackInvokedClosure = { trackEvent in
            assertDumpsEqual(trackEvent, event)
            trackExpectation.fulfill()
        }

        tracker.track(event)
    }
}
