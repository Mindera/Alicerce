import XCTest
@testable import Alicerce

final class BottomConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.translatesAutoresizingMaskIntoConstraints = false
        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true

        layoutGuide.widthAnchor.constraint(equalToConstant: 100).isActive = true
        layoutGuide.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithBottomConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view in
            constraint = view.bottom(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxY, 500)
    }

    func testConstrain_withBottomConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint1 = view0.bottom(to: host, relation: .equalOrLess)
            constraint2 = view0.bottom(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .lessThanOrEqual,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint1, expected1)

        let expected2 = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .greaterThanOrEqual,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint2, expected2)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxY, 500)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.bottom(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxY, 500 + 100)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.bottom(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: -100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxY, 500 - 100)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportTopAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.bottomToTop(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxY, 0)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.bottom(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .init(666),
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }

    func testConstrain_WithLayoutGuideBottomConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!

        constrain(host, layoutGuide) { host, layoutGuide in
            constraint = layoutGuide.bottom(to: host)
        }

        let expected = NSLayoutConstraint(
            item: layoutGuide!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(layoutGuide.layoutFrame.maxY, 500)
    }

    func testConstrain_WithAlignBottomConstraintAndEmptyArray_ShouldReturnEmptyArray() {

        let constraints = [UIView.ProxyType]().alignBottom()

        XCTAssertConstraints(constraints, [])
    }

    func testConstrain_WithAlignBottomConstraint_ShouldSupportRelativeEquality() {

        view1.translatesAutoresizingMaskIntoConstraints = false
        view2.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.bottom(to: host, offset: -50)
            constraints = [view0, view1, view2].alignBottom()
        }

        let expected = [
            NSLayoutConstraint(
                item: view0!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: view1,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view0!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: view2,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            )
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxY, view1.frame.maxY)
        XCTAssertEqual(view0.frame.maxY, view2.frame.maxY)
    }

    func testConstrain_WithBottomConstraintAndTwoConstraintGroups_ShouldReturnCorrectIsActiveValue() {

        var constraint0: NSLayoutConstraint!
        let constraintGroup0 =  constrain(host, view0, activate: false) { host, view0 in
            constraint0 = view0.bottom(to: host)
        }

        var constraint1: NSLayoutConstraint!
        let constraintGroup1 = constrain(host, view0, activate: false) { host, view0 in
            constraint1 = view0.bottom(to: host, offset: -100)
        }

        let expected = [
            NSLayoutConstraint(
                item: view0!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: host,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: false
            ),
            NSLayoutConstraint(
                item: view0!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: host,
                attribute: .bottom,
                multiplier: 1,
                constant: -100,
                priority: .required,
                active: false
            )
        ]

        XCTAssertConstraints([constraint0, constraint1], expected)

        constraintGroup0.isActive = true

        host.layoutIfNeeded()

        XCTAssert(constraintGroup0.isActive)
        XCTAssertFalse(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.maxY, 500)

        constraintGroup0.isActive = false
        constraintGroup1.isActive = true

        host.setNeedsLayout()
        host.layoutIfNeeded()

        XCTAssertFalse(constraintGroup0.isActive)
        XCTAssert(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.maxY, 400)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportFirstBaselineAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.bottomToFirstBaseline(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .firstBaseline,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportLastBaselineAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.bottomToLastBaseline(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .lastBaseline,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportCenterYAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.bottomToCenterY(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .centerY,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxY, host.center.y)
    }
}
