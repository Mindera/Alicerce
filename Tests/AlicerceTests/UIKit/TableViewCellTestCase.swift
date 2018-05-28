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

    func testInit_WithFrame_ShouldInvokeSetUpMethods() {

        let cell = MockTableViewCell(frame: .zero)

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
