import XCTest
@testable import Alicerce

final class CollectionReusableViewSizerTestCase: XCTestCase {

    private var reusableViewSizer: CollectionReusableViewSizer<MockSizerReusableView>!
    private var cellSizer: CollectionReusableViewSizer<MockSizerCell>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        reusableViewSizer = CollectionReusableViewSizer()
        cellSizer = CollectionReusableViewSizer()
    }

    override func tearDown() {

        reusableViewSizer = nil
        cellSizer = nil

        super.tearDown()
    }

    // MARK: - Tests

    // MARK: ReusableView

    func testSizer_WithReusableViewAndNoConstraints_ShouldReturnZeroSize() {

        let viewModel = MockSizerViewModel()
        let size = reusableViewSizer.sizeFor(viewModel: viewModel)

        XCTAssertEqual(size, CGSize(width: 0, height: 0))
    }

    func testSizer_WithReusableViewAndWidthConstraint_ShouldReturnCorrectSize() {

        let constraints: MockSizerViewModel.ConstraintClosure = { view in
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: 100)
            return [widthConstraint]
        }
        let viewModel = MockSizerViewModel(constraints: constraints)
        let size = reusableViewSizer.sizeFor(viewModel: viewModel)

        XCTAssertEqual(size, CGSize(width: 100, height: 0))
    }

    func testSizer_WithReusableViewAndBothConstraints_ShouldReturnCorrectSize() {

        let constraints: MockSizerViewModel.ConstraintClosure = { view in
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: 100)
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: 200)
            return [widthConstraint, heightConstraint]
        }
        let viewModel = MockSizerViewModel(constraints: constraints)
        let size = reusableViewSizer.sizeFor(viewModel: viewModel)

        XCTAssertEqual(size, CGSize(width: 100, height: 200))
    }

    func testSizer_WithReusableViewAndFixedDimension_ShouldReturnCorrectSize() {

        let constraints: MockSizerViewModel.ConstraintClosure = { view in
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: 50)
            widthConstraint.priority = .defaultHigh
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: 200)
            return [widthConstraint, heightConstraint]
        }
        let viewModel = MockSizerViewModel(constraints: constraints)
        let size = reusableViewSizer.sizeFor(viewModel: viewModel, width: .fixed(100))

        XCTAssertEqual(size, CGSize(width: 100, height: 200))
    }

    // MARK: Cell

    func testSizer_WithCellAndNoConstraints_ShouldReturnZeroSize() {

        let viewModel = MockSizerViewModel()
        let size = cellSizer.sizeFor(viewModel: viewModel)

        XCTAssertEqual(size, CGSize(width: 0, height: 0))
    }

    func testSizer_WithCellAndWidthConstraint_ShouldReturnCorrectSize() {

        let constraints: MockSizerViewModel.ConstraintClosure = { view in
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: 100)
            return [widthConstraint]
        }
        let viewModel = MockSizerViewModel(constraints: constraints)
        let size = cellSizer.sizeFor(viewModel: viewModel)

        XCTAssertEqual(size, CGSize(width: 100, height: 0))
    }

    func testSizer_WithCellAndBothConstraints_ShouldReturnCorrectSize() {

        let constraints: MockSizerViewModel.ConstraintClosure = { view in
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: 100)
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: 200)
            return [widthConstraint, heightConstraint]
        }
        let viewModel = MockSizerViewModel(constraints: constraints)
        let size = cellSizer.sizeFor(viewModel: viewModel)

        XCTAssertEqual(size, CGSize(width: 100, height: 200))
    }

    func testSizer_WithCellAndFixedDimension_ShouldReturnCorrectSize() {

        let constraints: MockSizerViewModel.ConstraintClosure = { view in
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: 50)
            widthConstraint.priority = .defaultHigh
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: 200)
            return [widthConstraint, heightConstraint]
        }
        let viewModel = MockSizerViewModel(constraints: constraints)
        let size = cellSizer.sizeFor(viewModel: viewModel, width: .fixed(100))

        XCTAssertEqual(size, CGSize(width: 100, height: 200))
    }
}

// MARK: - Mock Sizer ViewModel & Views

private final class MockSizerViewModel {

    typealias ConstraintClosure = (UIView) -> [NSLayoutConstraint]

    let constraints: ConstraintClosure?

    init(constraints: ConstraintClosure? = nil) {

        self.constraints = constraints
    }
}

private final class MockSizerReusableView: UICollectionReusableView, ReusableViewModelView {

    var viewModel: MockSizerViewModel? {
        didSet {
            setUpBindings()
        }
    }

    private var _constraints: [NSLayoutConstraint] = []

    func setUpSubviews() {}

    func setUpConstraints() {}

    func setUpBindings() {

        guard let viewModel = viewModel else { return }

        NSLayoutConstraint.deactivate(_constraints)

        _constraints = viewModel.constraints?(self) ?? []

        NSLayoutConstraint.activate(_constraints)
    }
}

private final class MockSizerCell: UICollectionViewCell, ReusableViewModelView {

    var viewModel: MockSizerViewModel? {
        didSet {
            setUpBindings()
        }
    }

    private var _constraints: [NSLayoutConstraint] = []

    func setUpSubviews() {}

    func setUpConstraints() {}

    func setUpBindings() {

        guard let viewModel = viewModel else { return }

        NSLayoutConstraint.deactivate(_constraints)

        _constraints = viewModel.constraints?(contentView) ?? []

        NSLayoutConstraint.activate(_constraints)
    }
}
