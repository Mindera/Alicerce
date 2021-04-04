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
