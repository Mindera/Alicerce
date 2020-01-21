import XCTest
@testable import Alicerce

class CenterXConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

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

    func testConstrain_WithOneCenterXConstraint_ShouldSupportRelativeCenterX() {

        constrain(host, view0) { host, view0 in
            constraint0 = view0.centerX(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.x, host.center.x)
    }

    func testConstrain_WithTwoCenterXConstraint_ShouldSupportRelativeCenterX() {

        constrain(host, view0, view1) { host, view0, view1 in
            constraint0 = view0.centerX(to: host)
            constraint1 = view1.centerX(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.x, host.center.x)
        XCTAssertEqual(view1.center.x, host.center.x)
    }

    func testConstrain_WithThreeCenterXConstraint_ShouldSupportRelativeCenterX() {

        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            constraint0 = view0.centerX(to: host)
            constraint1 = view1.centerX(to: host)
            constraint2 = view2.centerX(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, to: host))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.x, host.center.x)
        XCTAssertEqual(view1.center.x, host.center.x)
        XCTAssertEqual(view2.center.x, host.center.x)
    }

    func testConstrain_WithFourCenterXConstraint_ShouldSupportRelativeCenterX() {

        constrain(host, view0, view1, view2, view3) { host, view0, view1, view2, view3 in
            constraint0 = view0.centerX(to: host)
            constraint1 = view1.centerX(to: host)
            constraint2 = view2.centerX(to: host)
            constraint3 = view3.centerX(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, to: host))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, to: host))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.x, host.center.x)
        XCTAssertEqual(view1.center.x, host.center.x)
        XCTAssertEqual(view2.center.x, host.center.x)
        XCTAssertEqual(view3.center.x, host.center.x)
    }

    func testConstrain_WithFiveCenterXConstraint_ShouldSupportRelativeCenterX() {

        constrain(host, view0, view1, view2, view3, view4) { host, view0, view1, view2, view3, view4 in
            constraint0 = view0.centerX(to: host)
            constraint1 = view1.centerX(to: host)
            constraint2 = view2.centerX(to: host)
            constraint3 = view3.centerX(to: host)
            constraint4 = view4.centerX(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, to: host))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, to: host))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, to: host))
        XCTAssertConstraint(constraint4, expectedConstraint(view: view4, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.x, host.center.x)
        XCTAssertEqual(view1.center.x, host.center.x)
        XCTAssertEqual(view2.center.x, host.center.x)
        XCTAssertEqual(view3.center.x, host.center.x)
        XCTAssertEqual(view4.center.x, host.center.x)
    }

    func testConstrain_WithCenterXToLeadingConstraint_ShouldSupportRelativeCenterX() {

        constrain(host, view0) { host, view0 in
            constraint0 = view0.centerXToLeading(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint0, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.x, host.frame.minX)
    }

    func testConstrain_WithCenterXToTrailingConstraint_ShouldSupportRelativeCenterX() {

        constrain(host, view0) { host, view0 in
            constraint0 = view0.centerXToTrailing(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint0, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.x, host.frame.maxX)
    }

    func testConstrain_WithAlignCenterXConstraint_ShouldSupportRelativeEquality() {

        view1.translatesAutoresizingMaskIntoConstraints = false
        view2.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.centerX(to: host)
            constraints = [view0, view1, view2].alignCenterX()
        }

        let expected = [
            expectedConstraint(view: view0, to: view1),
            expectedConstraint(view: view0, to: view2)
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.midX, view1.frame.midX)
        XCTAssertEqual(view0.frame.midX, view2.frame.midX)
    }

    func testConstrain_WithLayoutGuideCenterXConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!

        constrain(host, layoutGuide) { host, layoutGuide in
            constraint = layoutGuide.centerX(to: host)
        }

        let expected = NSLayoutConstraint(
            item: layoutGuide!,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: host,
            attribute: .centerX,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(layoutGuide.layoutFrame.midX, host.frame.midX)
    }

    func testConstrain_WithCenterXConstraintAndEmptyArray_ShouldReturnEmptyArray() {

        let constraints = [UIView.ProxyType]().alignCenterX()

        XCTAssertConstraints(constraints, [])
    }
}

private extension CenterXConstrainableProxyTestCase {

    func expectedConstraint(view: UIView, to host: UIView) -> NSLayoutConstraint {

        NSLayoutConstraint(
            item: view,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: host,
            attribute: .centerX,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )
    }
}
