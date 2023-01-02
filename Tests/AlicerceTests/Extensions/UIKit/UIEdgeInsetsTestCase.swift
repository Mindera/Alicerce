import XCTest
import UIKit

@testable import Alicerce

final class UIEdgeInsetsTestCase: XCTestCase {

    func test_directional_ShouldReturnInstanceWithCorrectValues() {

        XCTAssertEqual(
            UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4).directional,
            NSDirectionalEdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        )
    }
}
