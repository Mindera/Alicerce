import Foundation
@testable import Alicerce

final class MockAnalyticsTracker<S, A, PK: AnalyticsParameterKey>: AnalyticsTracker  {

    typealias State = S
    typealias Action = A
    typealias ParameterKey = PK

    var mockID: ID?

    var trackInvokedClosure: ((Event) -> Void)?

    let defaultID: ID

    var id: ID { return mockID ?? defaultID }

    // MARK: - Lifecycle

    public init(id: ID = "MockSubTracker") {
        self.defaultID = id
    }

    func track(_ event: Event) {
        trackInvokedClosure?(event)
    }
}
