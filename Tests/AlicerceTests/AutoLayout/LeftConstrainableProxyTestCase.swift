import XCTest
@testable import Alicerce

final class LeftConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithLeftConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.left(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .left,
            relatedBy: .equal,
            toItem: host,
            attribute: .left,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 0)
    }

    func testConstrain_withLeftConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint1 = view0.left(to: host, relation: .equalOrLess)
            constraint2 = view0.left(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view0!,
            attribute: .left,
            relatedBy: .lessThanOrEqual,
            toItem: host,
            attribute: .left,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint1, expected1)

        let expected2 = NSLayoutConstraint(
            item: view0!,
            attribute: .left,
            relatedBy: .greaterThanOrEqual,
            toItem: host,
            attribute: .left,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint2, expected2)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 0)
    }

    func testConstrain_WithLeftConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.left(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .left,
            relatedBy: .equal,
            toItem: host,
            attribute: .left,
            multiplier: 1,
            constant: 100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 100)
    }

    func testConstrain_WithLeftConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.left(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .left,
            relatedBy: .equal,
            toItem: host,
            attribute: .left,
            multiplier: 1,
            constant: -100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, -100)
    }

    func testConstrain_WithLeftConstraint_ShouldSupportRightAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leftToRight(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .left,
            relatedBy: .equal,
            toItem: host,
            attribute: .right,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 500)
    }

    func testConstrain_WithLeftConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.left(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .left,
            relatedBy: .equal,
            toItem: host,
            attribute: .left,
            multiplier: 1,
            constant: 0,
            priority: .init(666),
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }
}
