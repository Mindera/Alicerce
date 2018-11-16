import Foundation
@testable import Alicerce

final class MockCancelable: Cancelable {

    var mockIsCancelled: Bool = false
    var mockCancelClosure: (() -> Void)?

    var isCancelled: Bool { return mockIsCancelled }

    public func cancel() {
        mockCancelClosure?()
    }
}
