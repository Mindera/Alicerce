import XCTest
import UIKit
@testable import Alicerce

class ReusableViewTestCase: XCTestCase {

    static var customName = "CustomName"

    func testReuseIdentifier_WithDefaultImplementation_ShouldReturnTypeName() {

        XCTAssertEqual(TestCollectionViewCell.reuseIdentifier, "\(TestCollectionViewCell.self)")
        XCTAssertEqual(TestCollectionReusableView.reuseIdentifier, "\(TestCollectionReusableView.self)")
        XCTAssertEqual(TestTableViewCell.reuseIdentifier, "\(TestTableViewCell.self)")
        XCTAssertEqual(TestTableViewHeaderFooterView.reuseIdentifier, "\(TestTableViewHeaderFooterView.self)")
    }

    func testReuseIdentifier_WithCustomImplementation_ShouldReturnCustomName() {

        XCTAssertEqual(TestCustomNameView.reuseIdentifier, ReusableViewTestCase.customName)
    }
}

private final class TestCollectionViewCell: UICollectionViewCell {}
private final class TestCollectionReusableView: UICollectionReusableView {}
private final class TestTableViewCell: UITableViewCell {}
private final class TestTableViewHeaderFooterView: UITableViewHeaderFooterView {}

private final class TestCustomNameView: UIView {
    static var reuseIdentifier = ReusableViewTestCase.customName
}
