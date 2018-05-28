import Foundation

@testable import Alicerce

struct MockReusableViewModelView {
    let testProperty = "😎"
}

extension MockReusableViewModelView: Equatable {
    static func ==(lhs: MockReusableViewModelView, rhs: MockReusableViewModelView) -> Bool {
        return lhs.testProperty == rhs.testProperty
    }
}
