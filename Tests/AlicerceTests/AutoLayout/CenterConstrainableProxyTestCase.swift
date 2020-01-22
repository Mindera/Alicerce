import XCTest
@testable import Alicerce

class CenterConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    private(set) var constraints0: [NSLayoutConstraint]!
    private(set) var constraints1: [NSLayoutConstraint]!
    private(set) var constraints2: [NSLayoutConstraint]!
    private(set) var constraints3: [NSLayoutConstraint]!
    private(set) var constraints4: [NSLayoutConstraint]!
    private(set) var constraints5: [NSLayoutConstraint]!

    override func tearDown() {

        constraints0 = nil
        constraints1 = nil
        constraints2 = nil
        constraints3 = nil
        constraints4 = nil
        constraints5 = nil

        super.tearDown()
    }

    func testConstrain_WithOneCenterConstraint_ShouldSupportRelativeCenter() {

        constrain(host, view0) { host, view0 in
            constraints0 = view0.center(in: host)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center, host.center)
    }

    func testConstrain_WithTwoCenterConstraint_ShouldSupportRelativeCenter() {

        constrain(host, view0, view1) { host, view0, view1 in
            constraints0 = view0.center(in: host)
            constraints1 = view1.center(in: host)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, to: host))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center, host.center)
        XCTAssertEqual(view1.center, host.center)
    }

    func testConstrain_WithThreeCenterConstraint_ShouldSupportRelativeCenter() {

        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            constraints0 = view0.center(in: host)
            constraints1 = view1.center(in: host)
            constraints2 = view2.center(in: host)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, to: host))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, to: host))
        XCTAssertConstraints(constraints2, expectedConstraints(view: view2, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center, host.center)
        XCTAssertEqual(view1.center, host.center)
        XCTAssertEqual(view2.center, host.center)
    }

    func testConstrain_WithFourCenterConstraint_ShouldSupportRelativeCenter() {

        constrain(host, view0, view1, view2, view3) { host, view0, view1, view2, view3 in
            constraints0 = view0.center(in: host)
            constraints1 = view1.center(in: host)
            constraints2 = view2.center(in: host)
            constraints3 = view3.center(in: host)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, to: host))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, to: host))
        XCTAssertConstraints(constraints2, expectedConstraints(view: view2, to: host))
        XCTAssertConstraints(constraints3, expectedConstraints(view: view3, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center, host.center)
        XCTAssertEqual(view1.center, host.center)
        XCTAssertEqual(view2.center, host.center)
        XCTAssertEqual(view3.center, host.center)
    }

    func testConstrain_WithFiveCenterConstraint_ShouldSupportRelativeCenter() {

        constrain(host, view0, view1, view2, view3, view4) { host, view0, view1, view2, view3, view4 in
            constraints0 = view0.center(in: host)
            constraints1 = view1.center(in: host)
            constraints2 = view2.center(in: host)
            constraints3 = view3.center(in: host)
            constraints4 = view4.center(in: host)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, to: host))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, to: host))
        XCTAssertConstraints(constraints2, expectedConstraints(view: view2, to: host))
        XCTAssertConstraints(constraints3, expectedConstraints(view: view3, to: host))
        XCTAssertConstraints(constraints4, expectedConstraints(view: view4, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.center, host.center)
        XCTAssertEqual(view1.center, host.center)
        XCTAssertEqual(view2.center, host.center)
        XCTAssertEqual(view3.center, host.center)
        XCTAssertEqual(view4.center, host.center)
    }
}

private extension CenterConstrainableProxyTestCase {

    func expectedConstraints(view: UIView, to host: UIView) -> [NSLayoutConstraint] {

        let centerX = NSLayoutConstraint(
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

        let centerY = NSLayoutConstraint(
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

        return [centerX, centerY]
    }
}
