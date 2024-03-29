import XCTest
@testable import Alicerce

final class LeftConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.translatesAutoresizingMaskIntoConstraints = false
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

    func testConstrain_WithLeftConstraint_ShouldSupportCenterXAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leftToCenterX(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .left,
            relatedBy: .equal,
            toItem: host,
            attribute: .centerX,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, host.center.x)
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

    func testConstrain_WithLayoutGuideLeftConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!

        constrain(host, layoutGuide) { host, layoutGuide in
            constraint = layoutGuide.left(to: host)
        }

        let expected = NSLayoutConstraint(
            item: layoutGuide!,
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

        XCTAssertEqual(layoutGuide.layoutFrame.minX, host.frame.minX)
    }

    func testConstrain_WithLeftConstraintAndTwoConstraintGroups_ShouldReturnCorrectIsActiveConstraint() {

        var constraint0: NSLayoutConstraint!
        var constraint1: NSLayoutConstraint!

        let constraintGroup0 = constrain(host, view0, activate: false) { host, view0 in
            constraint0 = view0.left(to: host)
        }

        let constraintGroup1 = constrain(host, view0, activate: false) { host, view0 in
            constraint1 = view0.left(to: host, offset: 100)
        }

        let expected = [
            NSLayoutConstraint(
                item: view0!,
                attribute: .left,
                relatedBy: .equal,
                toItem: host,
                attribute: .left,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: false
            ),
            NSLayoutConstraint(
                item: view0!,
                attribute: .left,
                relatedBy: .equal,
                toItem: host,
                attribute: .left,
                multiplier: 1,
                constant: 100,
                priority: .required,
                active: false
            )
        ]

        XCTAssertConstraints([constraint0, constraint1], expected)

        constraintGroup0.isActive = true

        host.layoutIfNeeded()

        XCTAssert(constraintGroup0.isActive)
        XCTAssertFalse(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.minX, host.frame.minX)

        constraintGroup0.isActive = false
        constraintGroup1.isActive = true

        host.setNeedsLayout()
        host.layoutIfNeeded()

        XCTAssertFalse(constraintGroup0.isActive)
        XCTAssert(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.minX, host.frame.minX + 100)
    }
}
