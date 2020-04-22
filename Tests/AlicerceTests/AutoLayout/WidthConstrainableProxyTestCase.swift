import XCTest
@testable import Alicerce

class WidthConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    private(set) var constraint0: NSLayoutConstraint!
    private(set) var constraint1: NSLayoutConstraint!
    private(set) var constraint2: NSLayoutConstraint!
    private(set) var constraint3: NSLayoutConstraint!
    private(set) var constraint4: NSLayoutConstraint!
    private(set) var constraint5: NSLayoutConstraint!

    override func tearDown() {

        constraint0 = nil
        constraint1 = nil
        constraint2 = nil
        constraint3 = nil
        constraint4 = nil
        constraint5 = nil

        super.tearDown()
    }

    func testConstrain_WithOneWidthConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0) { view0 in
            constraint0 = view0.width(Constants.width0)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, width: Constants.width0))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, Constants.width0)
    }

    func testConstrain_WithTwoWidthConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1) { view0, view1 in
            constraint0 = view0.width(Constants.width0)
            constraint1 = view1.width(Constants.width1)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, width: Constants.width0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, width: Constants.width1))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, Constants.width0)
        XCTAssertEqual(view1.frame.width, Constants.width1)
    }

    func testConstrain_WithThreeWidthConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1, view2) { view0, view1, view2 in
            constraint0 = view0.width(Constants.width0)
            constraint1 = view1.width(Constants.width1)
            constraint2 = view2.width(Constants.width2)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, width: Constants.width0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, width: Constants.width1))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, width: Constants.width2))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, Constants.width0)
        XCTAssertEqual(view1.frame.width, Constants.width1)
        XCTAssertEqual(view2.frame.width, Constants.width2)
    }

    func testConstrain_WithFourWidthConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1, view2, view3) { view0, view1, view2, view3 in
            constraint0 = view0.width(Constants.width0)
            constraint1 = view1.width(Constants.width1)
            constraint2 = view2.width(Constants.width2)
            constraint3 = view3.width(Constants.width3)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, width: Constants.width0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, width: Constants.width1))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, width: Constants.width2))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, width: Constants.width3))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, Constants.width0)
        XCTAssertEqual(view1.frame.width, Constants.width1)
        XCTAssertEqual(view2.frame.width, Constants.width2)
        XCTAssertEqual(view3.frame.width, Constants.width3)
    }

    func testConstrain_WithFiveWidthConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1, view2, view3, view4) { view0, view1, view2, view3, view4 in
            constraint0 = view0.width(Constants.width0)
            constraint1 = view1.width(Constants.width1)
            constraint2 = view2.width(Constants.width2)
            constraint3 = view3.width(Constants.width3)
            constraint4 = view4.width(Constants.width4)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, width: Constants.width0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, width: Constants.width1))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, width: Constants.width2))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, width: Constants.width3))
        XCTAssertConstraint(constraint4, expectedConstraint(view: view4, width: Constants.width4))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, Constants.width0)
        XCTAssertEqual(view1.frame.width, Constants.width1)
        XCTAssertEqual(view2.frame.width, Constants.width2)
        XCTAssertEqual(view3.frame.width, Constants.width3)
        XCTAssertEqual(view4.frame.width, Constants.width4)
    }

    func testConstrain_WithSixWidthConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1, view2, view3, view4, view5) { view0, view1, view2, view3, view4, view5 in
            constraint0 = view0.width(Constants.width0)
            constraint1 = view1.width(Constants.width1)
            constraint2 = view2.width(Constants.width2)
            constraint3 = view3.width(Constants.width3)
            constraint4 = view4.width(Constants.width4)
            constraint5 = view5.width(Constants.width5)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, width: Constants.width0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, width: Constants.width1))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, width: Constants.width2))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, width: Constants.width3))
        XCTAssertConstraint(constraint4, expectedConstraint(view: view4, width: Constants.width4))
        XCTAssertConstraint(constraint5, expectedConstraint(view: view5, width: Constants.width5))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, Constants.width0)
        XCTAssertEqual(view1.frame.width, Constants.width1)
        XCTAssertEqual(view2.frame.width, Constants.width2)
        XCTAssertEqual(view3.frame.width, Constants.width3)
        XCTAssertEqual(view4.frame.width, Constants.width4)
        XCTAssertEqual(view5.frame.width, Constants.width5)
    }

    func testConstrain_WithWidthConstraint_ShouldSupportRelativeWidth() {

        constrain(host, view0) { host, view0 in
            constraint0 = view0.width(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, host.frame.width)
    }

    func testConstrain_WithWidthConstantConstraint_ShouldSupportRelativeEquality() {

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            constraints = [view0, view1, view2].equal(width: Constants.width0)
        }

        let expected = [
            expectedConstraint(view: view0, width: Constants.width0),
            expectedConstraint(view: view1, width: Constants.width0),
            expectedConstraint(view: view2, width: Constants.width0)
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, Constants.width0)
        XCTAssertEqual(view1.frame.width, Constants.width0)
        XCTAssertEqual(view2.frame.width, Constants.width0)
    }

    func testConstrain_WithWidthConstraint_ShouldSupportRelativeEquality() {

        view1.translatesAutoresizingMaskIntoConstraints = false
        view2.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.width(Constants.width0)
            constraints = [view0, view1, view2].equalWidth()
        }

        let expected = [
            expectedConstraint(view: view0, to: view1),
            expectedConstraint(view: view0, to: view2)
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.width, Constants.width0)
        XCTAssertEqual(view0.frame.width, view1.frame.width)
        XCTAssertEqual(view0.frame.width, view2.frame.width)
    }

    func testConstrain_WithLayoutGuideWidthConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!

        constrain(host, layoutGuide) { host, layoutGuide in
            constraint = layoutGuide.width(to: host)
        }

        let expected = NSLayoutConstraint(
            item: layoutGuide!,
            attribute: .width,
            relatedBy: .equal,
            toItem: host,
            attribute: .width,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(layoutGuide.layoutFrame.width, host.frame.width)
    }

    func testConstrain_WithWidthConstraintAndEmptyArray_ShouldReturnEmptyArray() {

        let constraints = [UIView.ProxyType]().equalWidth()

        XCTAssertConstraints(constraints, [])
    }

    func testConstrain_WithWidthConstraintAndTwoConstraintGroups_ShouldReturnCorrectIsActiveConstraint() {

        let constraintGroup0 = constrain(view0, activate: false) { view0 in
            constraint0 = view0.width(Constants.width0)
        }

        let constraintGroup1 = constrain(view0, activate: false) { view0 in
            constraint1 = view0.width(Constants.width1)
        }

        XCTAssertConstraints(
            [constraint0, constraint1],
            [
                expectedConstraint(view: view0, width: Constants.width0, active: false),
                expectedConstraint(view: view0, width: Constants.width1, active: false)
            ]
        )

        constraintGroup0.isActive = true

        host.layoutIfNeeded()

        XCTAssert(constraintGroup0.isActive)
        XCTAssertFalse(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.width, Constants.width0)

        constraintGroup0.isActive = false
        constraintGroup1.isActive = true

        host.setNeedsLayout()
        host.layoutIfNeeded()

        XCTAssertFalse(constraintGroup0.isActive)
        XCTAssert(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.width, Constants.width1)
    }
}

private extension WidthConstrainableProxyTestCase {

    func expectedConstraint(view: UIView, width: CGFloat, active: Bool = true) -> NSLayoutConstraint {

        NSLayoutConstraint(
            item: view,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .width,
            multiplier: 1,
            constant: width,
            priority: .required,
            active: active
        )
    }

    func expectedConstraint(view: UIView, to host: UIView) -> NSLayoutConstraint {

        NSLayoutConstraint(
            item: view,
            attribute: .width,
            relatedBy: .equal,
            toItem: host,
            attribute: .width,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )
    }

}

private enum Constants {

    static let width0: CGFloat = 100
    static let width1: CGFloat = 200
    static let width2: CGFloat = 300
    static let width3: CGFloat = 400
    static let width4: CGFloat = 500
    static let width5: CGFloat = 600
}
