import XCTest
@testable import Alicerce

class CenterYConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

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

    func testConstrain_WithOneCenterYConstraint_ShouldSupportRelativeCenterY() {

        constrain(host, view0) { host, view0 in
            constraint0 = view0.centerY(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.y, host.center.y)
    }

    func testConstrain_WithTwoCenterYConstraint_ShouldSupportRelativeCenterY() {

        constrain(host, view0, view1) { host, view0, view1 in
            constraint0 = view0.centerY(to: host)
            constraint1 = view1.centerY(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.y, host.center.y)
        XCTAssertEqual(view1.center.y, host.center.y)
    }

    func testConstrain_WithThreeCenterYConstraint_ShouldSupportRelativeCenterY() {

        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            constraint0 = view0.centerY(to: host)
            constraint1 = view1.centerY(to: host)
            constraint2 = view2.centerY(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, to: host))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.y, host.center.y)
        XCTAssertEqual(view1.center.y, host.center.y)
        XCTAssertEqual(view2.center.y, host.center.y)
    }

    func testConstrain_WithFourCenterYConstraint_ShouldSupportRelativeCenterY() {

        constrain(host, view0, view1, view2, view3) { host, view0, view1, view2, view3 in
            constraint0 = view0.centerY(to: host)
            constraint1 = view1.centerY(to: host)
            constraint2 = view2.centerY(to: host)
            constraint3 = view3.centerY(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, to: host))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, to: host))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.y, host.center.y)
        XCTAssertEqual(view1.center.y, host.center.y)
        XCTAssertEqual(view2.center.y, host.center.y)
        XCTAssertEqual(view3.center.y, host.center.y)
    }

    func testConstrain_WithFiveCenterYConstraint_ShouldSupportRelativeCenterY() {

        constrain(host, view0, view1, view2, view3, view4) { host, view0, view1, view2, view3, view4 in
            constraint0 = view0.centerY(to: host)
            constraint1 = view1.centerY(to: host)
            constraint2 = view2.centerY(to: host)
            constraint3 = view3.centerY(to: host)
            constraint4 = view4.centerY(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, to: host))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, to: host))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, to: host))
        XCTAssertConstraint(constraint4, expectedConstraint(view: view4, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.y, host.center.y)
        XCTAssertEqual(view1.center.y, host.center.y)
        XCTAssertEqual(view2.center.y, host.center.y)
        XCTAssertEqual(view3.center.y, host.center.y)
        XCTAssertEqual(view4.center.y, host.center.y)
    }

    func testConstrain_WithCenterYToTopConstraint_ShouldSupportRelativeCenterY() {

        constrain(host, view0) { host, view0 in
            constraint0 = view0.centerYToTop(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint0, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.y, host.frame.minY)
    }

    func testConstrain_WithCenterYToBottomConstraint_ShouldSupportRelativeCenterY() {

        constrain(host, view0) { host, view0 in
            constraint0 = view0.centerYToBottom(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint0, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center.y, host.frame.maxY)
    }

    func testConstrain_WithAlignCenterXConstraint_ShouldSupportRelativeEquality() {

        view1.translatesAutoresizingMaskIntoConstraints = false
        view2.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.centerY(to: host)
            constraints = [view0, view1, view2].alignCenterY()
        }

        let expected = [
            expectedConstraint(view: view0, to: view1),
            expectedConstraint(view: view0, to: view2)
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.midY, view1.frame.midY)
        XCTAssertEqual(view0.frame.midY, view2.frame.midY)
    }
}

private extension CenterYConstrainableProxyTestCase {

    func expectedConstraint(view: UIView, to host: UIView) -> NSLayoutConstraint {

        NSLayoutConstraint(
            item: view,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: host,
            attribute: .centerY,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )
    }
}
