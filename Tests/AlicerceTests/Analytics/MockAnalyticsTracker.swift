import Foundation
@testable import Alicerce

final class MockAnalyticsTracker<S, A, PK: AnalyticsParameterKey>: AnalyticsTracker  {

    typealias State = S
    typealias Action = A
    typealias ParameterKey = PK

    var trackInvokedClosure: ((Event) -> Void)?

    let id: UUID

    init(id: UUID = .init()) { self.id = id }

    func track(_ event: Event) { trackInvokedClosure?(event) }
}
