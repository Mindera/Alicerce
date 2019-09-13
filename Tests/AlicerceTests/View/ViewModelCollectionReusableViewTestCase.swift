import XCTest

@testable import Alicerce

final class MockViewModelCollectionReusableView: ViewModelCollectionReusableView<MockReusableViewModelView> {

    private(set) var setUpSubviewsCallCount = 0
    private(set) var setUpConstraintsCallCount = 0
    private(set) var setUpBindingsCallCount = 0
    private(set) var prepareForReuseCallCount = 0

    override func setUpSubviews() {
        super.setUpSubviews()
        setUpSubviewsCallCount += 1
    }

    override func setUpConstraints() {
        super.setUpConstraints()
        setUpConstraintsCallCount += 1
    }

    override func setUpBindings() {
        super.setUpBindings()
        setUpBindingsCallCount += 1
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        prepareForReuseCallCount += 1
    }
}

final class ViewModelCollectionReusableViewTestCase: XCTestCase {
    
    func testInit_WithFrame_ShouldInvokeSetUpMethods() {

        let cell = MockViewModelCollectionReusableView()

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)
        XCTAssertNil(cell.viewModel)

        let viewModel = MockReusableViewModelView()
        cell.viewModel = viewModel

        XCTAssertNotNil(cell.viewModel)
        XCTAssertEqual(cell.viewModel, viewModel)
        XCTAssertEqual(cell.setUpBindingsCallCount, 1)
    }

    func testInit_WithCoder_ShouldInvokeSetUpMethods() {

        guard let cell: MockViewModelCollectionReusableView = UIView.instantiateFromNib(withOwner: self) else {
            return XCTFail("failed to load view from nib!")
        }

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)

        XCTAssertNil(cell.viewModel)

        let viewModel = MockReusableViewModelView()
        cell.viewModel = viewModel

        XCTAssertNotNil(cell.viewModel)
        XCTAssertEqual(cell.viewModel, viewModel)
        XCTAssertEqual(cell.setUpBindingsCallCount, 1)
    }

    func testReuse_WithoutViewModel_ShouldEndWithoutViewModel() {

        let cell = MockViewModelCollectionReusableView()

        XCTAssertNil(cell.viewModel)

        cell.prepareForReuse()

        XCTAssertNil(cell.viewModel)
        XCTAssertEqual(cell.setUpBindingsCallCount, 1)
        XCTAssertEqual(cell.prepareForReuseCallCount, 1)
    }

    func testReuse_WithViewModel_ShouldEndWithoutViewModel() {

        let cell = MockViewModelCollectionReusableView()

        cell.viewModel = MockReusableViewModelView()

        XCTAssertNotNil(cell.viewModel)
        XCTAssertEqual(cell.setUpBindingsCallCount, 1)

        cell.prepareForReuse()

        XCTAssertNil(cell.viewModel)
        XCTAssertEqual(cell.setUpBindingsCallCount, 2)
        XCTAssertEqual(cell.prepareForReuseCallCount, 1)
    }
}
