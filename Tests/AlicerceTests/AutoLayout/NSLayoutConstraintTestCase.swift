import XCTest
@testable import Alicerce

final class NSLayoutConstraintTestCase: XCTestCase {

    var host: UIView!
    var constraint: NSLayoutConstraint!

    override func setUp() {

        host = UIView()
        let view = UIView()

        host.addSubview(view)

        constraint = NSLayoutConstraint(
            item: view,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 10
        )

        super.setUp()
    }

    override func tearDown() {

        constraint = nil
        host = nil

        super.tearDown()
    }

    // MARK: - Priorities

    func testWithPriority_WithDefaultValues_ShouldUpdatePriority() {

        _ = constraint.with(priority: .defaultLow)
        XCTAssertEqual(constraint.priority, .defaultLow)

        _ = constraint.with(priority: .defaultHigh)
        XCTAssertEqual(constraint.priority, .defaultHigh)

        _ = constraint.with(priority: .fittingSizeLevel)
        XCTAssertEqual(constraint.priority, .fittingSizeLevel)

        _ = constraint.with(priority: .required)
        XCTAssertEqual(constraint.priority, .required)
    }

    func testWithPriority_WithCustomValues_ShouldUpdatePriority() {

        _ = constraint.with(priority: .init(666))
        XCTAssertEqual(constraint.priority, .init(666))

        _ = constraint.with(priority: .init(1))
        XCTAssertEqual(constraint.priority, .init(1))
    }

    func testWithPriority_WithAnyValue_ShouldReturnItself() {

        XCTAssert(constraint.with(priority: .defaultHigh) === constraint)
        XCTAssert(constraint.with(priority: .init(666)) === constraint)
    }

    // MARK: - Activation

    func testSetActive_WithTrue_ShouldActivateConstraint() {

        constraint.isActive = false

        _ = constraint.set(active: true)
        XCTAssertTrue(constraint.isActive)
    }

    func testSetActive_WithFalse_ShouldDeactivateConstraint() {

        constraint.isActive = true

        _ = constraint.set(active: false)
        XCTAssertFalse(constraint.isActive)
    }

    func testSetActive_WithAnyValue_ShouldReturnItself() {

        XCTAssert(constraint.set(active: false) === constraint)
        XCTAssert(constraint.set(active: true) === constraint)
    }
}
