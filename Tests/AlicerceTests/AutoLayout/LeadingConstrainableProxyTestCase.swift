import XCTest
@testable import Alicerce

final class LeadingConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.translatesAutoresizingMaskIntoConstraints = false
        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leading(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 0)
    }

    func testConstrain_withLeadingConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint1 = view0.leading(to: host, relation: .equalOrLess)
            constraint2 = view0.leading(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .lessThanOrEqual,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint1, expected1)

        let expected2 = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .greaterThanOrEqual,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint2, expected2)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 0)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leading(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 100)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leading(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: -100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, -100)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportTrailingAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leadingToTrailing(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 500)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportCenterXAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leadingToCenterX(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .centerX,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 250)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leading(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .init(666),
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }

    func testConstrain_WithLayoutGuideLeadingConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!

        constrain(host, layoutGuide) { host, layoutGuide in
            constraint = layoutGuide.leading(to: host)
        }

        let expected = NSLayoutConstraint(
            item: layoutGuide!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(layoutGuide.layoutFrame.minX, host.frame.minX)
    }

    func testConstrain_WithAlignLeadingConstraintAndEmptyArray_ShouldReturnEmptyArray() {

        let constraints = [UIView.ProxyType]().alignLeading()

        XCTAssertConstraints(constraints, [])
    }

    func testConstrain_WithAlignLeadingConstraint_ShouldSupportRelativeEquality() {

        view1.translatesAutoresizingMaskIntoConstraints = false
        view2.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.leading(to: host, offset: 50)
            constraints = [view0, view1, view2].alignLeading()
        }

        let expected = [
            NSLayoutConstraint(
                item: view0!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view1,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view0!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view2,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            )
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, view1.frame.minX)
        XCTAssertEqual(view0.frame.minX, view2.frame.minX)
    }

    func testConstrain_WithLeadingConstraintAndTwoConstraintGroups_ShouldReturnCorrectIsActiveConstraint() {

        var constraint0: NSLayoutConstraint!
        var constraint1: NSLayoutConstraint!

        let constraintGroup0 = constrain(host, view0, activate: false) { host, view0 in
            constraint0 = view0.leading(to: host)
        }

        let constraintGroup1 = constrain(host, view0, activate: false) { host, view0 in
            constraint1 = view0.leading(to: host, offset: 100)
        }

        let expected = [
            NSLayoutConstraint(
                item: view0!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: host,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: false
            ),
            NSLayoutConstraint(
                item: view0!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: host,
                attribute: .leading,
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
