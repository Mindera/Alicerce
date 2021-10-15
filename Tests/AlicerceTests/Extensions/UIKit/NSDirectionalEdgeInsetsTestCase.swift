import XCTest
import UIKit

@testable import Alicerce

@available(iOS 11.0, *)
final class NSDirectionalEdgeInsetsTestCase: XCTestCase {

    func test_nonDirectional_ShouldReturnInstanceWithCorrectValues() {

        XCTAssertEqual(
            NSDirectionalEdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4).nonDirectional,
            UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        )
    }
}
