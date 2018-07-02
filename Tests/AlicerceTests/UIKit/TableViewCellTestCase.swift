import XCTest
@testable import Alicerce

final class MockTableViewCell: TableViewCell {

    private(set) var setUpSubviewsCallCount = 0
    private(set) var setUpConstraintsCallCount = 0

    override func setUpSubviews() {
        super.setUpSubviews()
        setUpSubviewsCallCount += 1
    }

    override func setUpConstraints() {
        super.setUpConstraints()
        setUpConstraintsCallCount += 1
    }
}

class TableViewCellTestCase: XCTestCase {

    func testInit_WithStyleAndReuseIdentifier_ShouldCreateInstance() {

        let _ = TableViewCell(style: .default, reuseIdentifier: nil)
    }

    func testInit_WithCoder_ShouldCreateInstance() {

        guard let _: TableViewCell = UIView.instantiateFromNib(withOwner: self, bundle: Bundle(for: TestDummy.self))
        else {
            return XCTFail("failed to load view from nib!")
        }
    }

    func testInit_WithStyleAndReuseIdentifier_ShouldInvokeSetUpMethods() {

        let cell = MockTableViewCell(style: .default, reuseIdentifier: nil)

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)
    }

    func testInit_WithCoder_ShouldInvokeSetUpMethods() {

        guard let cell: MockTableViewCell = UIView.instantiateFromNib(withOwner: self) else {
            return XCTFail("failed to load view from nib!")
        }

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)
    }
}
