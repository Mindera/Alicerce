import XCTest
@testable import Alicerce

final class MockCollectionViewCell: CollectionViewCell {

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

class CollectionViewCellTestCase: XCTestCase {

    func testInit_WithFrame_ShouldCreateInstance() {

        let _ = CollectionViewCell(frame: .zero)
    }

    func testInit_WithCoder_ShouldCreateInstance() {

        guard let _: CollectionViewCell = UIView.instantiateFromNib(withOwner: self,
                                                                    bundle: Bundle(for: TestDummy.self))
        else {
            return XCTFail("failed to load view from nib!")
        }
    }

    func testInit_WithFrame_ShouldInvokeSetUpMethods() {

        let cell = MockCollectionViewCell(frame: .zero)

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)
    }

    func testInit_WithCoder_ShouldInvokeSetUpMethods() {

        guard let cell: MockCollectionViewCell = UIView.instantiateFromNib(withOwner: self) else {
            return XCTFail("failed to load view from nib!")
        }

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)
    }
}
