import XCTest
@testable import Alicerce

final class Analytics_MultiTrackerTestCase: XCTestCase {

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

    // init

    func testInit_WithResultBuilder_ShouldInstantiateCorrectTrackers() {

        let subTracker1 = MockSubTracker()
        let subTracker2 = MockSubTracker()
        let subTracker3 = MockSubTracker()
        let subTracker4 = MockSubTracker()
        let subTrackerOpt = MockSubTracker()
        let subTrackerTrue = MockSubTracker()
        let subTrackerFalse = MockSubTracker()
        let subTrackerArray = (1...3).map { _ in MockSubTracker() }
        let subTrackerAvailable = MockSubTracker()

        let optVar: Bool? = true
        let optNil: Bool? = nil
        let trueVar = true
        let falseVar = false

        let tracker = MultiTracker {
            subTracker1
            subTracker2

            subTracker3.eraseToAnyAnalyticsTracker()

            [subTracker4].map { $0.eraseToAnyAnalyticsTracker() }

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
            (
                [
                    subTracker1,
                    subTracker2,
                    subTracker3,
                    subTracker4,
                    subTrackerOpt,
                    subTrackerTrue,
                    subTrackerFalse
                ]
                + subTrackerArray
                + [subTrackerAvailable]
            )
            .map { $0.eraseToAnyAnalyticsTracker() }
        )
    }

    // track

    func testTrack_WithActionEvent_ShouldCallTrackOnAlltrackers() {

        let trackExpectation = self.expectation(description: "track")
        trackExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let subTracker1 = MockSubTracker()
        let subTracker2 = MockSubTracker()

        let tracker = MultiTracker(trackers: [subTracker1, subTracker2].map { $0.eraseToAnyAnalyticsTracker() })

        let event = MultiTracker.Event.action(.🔨, [.language : "🇵🇹", .date : Date()])

        subTracker1.trackInvokedClosure = { trackEvent in
            XCTAssertDumpsEqual(trackEvent, event)
            trackExpectation.fulfill()
        }

        subTracker2.trackInvokedClosure = { trackEvent in
            XCTAssertDumpsEqual(trackEvent, event)
            trackExpectation.fulfill()
        }

        tracker.track(event)
    }

    func testTrack_WithStateEvent_ShouldCallTrackOnAlltrackers() {

        let trackExpectation = self.expectation(description: "track")
        trackExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let subTracker1 = MockSubTracker()
        let subTracker2 = MockSubTracker()

        let tracker = MultiTracker(trackers: [subTracker1, subTracker2].map { $0.eraseToAnyAnalyticsTracker() })

        let event = MultiTracker.Event.state(.screen(name: "🖼"), [.language : "🇵🇹", .date : Date()])

        subTracker1.trackInvokedClosure = { trackEvent in
            XCTAssertDumpsEqual(trackEvent, event)
            trackExpectation.fulfill()
        }

        subTracker2.trackInvokedClosure = { trackEvent in
            XCTAssertDumpsEqual(trackEvent, event)
            trackExpectation.fulfill()
        }

        tracker.track(event)
    }
}
