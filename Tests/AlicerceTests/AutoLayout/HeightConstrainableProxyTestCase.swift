import XCTest
@testable import Alicerce

class HeightConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

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

    func testConstrain_WithOneHeightConstraint_ShouldSupportAbsoluteHeight() {

        constrain(view0) { view0 in
            constraint0 = view0.height(Constants.height0)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, height: Constants.height0))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.height, Constants.height0)
    }

    func testConstrain_WithTwoHeightConstraint_ShouldSupportAbsoluteHeight() {

        constrain(view0, view1) { view0, view1 in
            constraint0 = view0.height(Constants.height0)
            constraint1 = view1.height(Constants.height1)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, height: Constants.height0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, height: Constants.height1))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.height, Constants.height0)
        XCTAssertEqual(view1.frame.height, Constants.height1)
    }

    func testConstrain_WithThreeHeightConstraint_ShouldSupportAbsoluteHeight() {

        constrain(view0, view1, view2) { view0, view1, view2 in
            constraint0 = view0.height(Constants.height0)
            constraint1 = view1.height(Constants.height1)
            constraint2 = view2.height(Constants.height2)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, height: Constants.height0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, height: Constants.height1))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, height: Constants.height2))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.height, Constants.height0)
        XCTAssertEqual(view1.frame.height, Constants.height1)
        XCTAssertEqual(view2.frame.height, Constants.height2)
    }

    func testConstrain_WithFourHeightConstraint_ShouldSupportAbsoluteHeight() {

        constrain(view0, view1, view2, view3) { view0, view1, view2, view3 in
            constraint0 = view0.height(Constants.height0)
            constraint1 = view1.height(Constants.height1)
            constraint2 = view2.height(Constants.height2)
            constraint3 = view3.height(Constants.height3)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, height: Constants.height0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, height: Constants.height1))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, height: Constants.height2))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, height: Constants.height3))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.height, Constants.height0)
        XCTAssertEqual(view1.frame.height, Constants.height1)
        XCTAssertEqual(view2.frame.height, Constants.height2)
        XCTAssertEqual(view3.frame.height, Constants.height3)
    }

    func testConstrain_WithFiveHeightConstraint_ShouldSupportAbsoluteHeight() {

        constrain(view0, view1, view2, view3, view4) { view0, view1, view2, view3, view4 in
            constraint0 = view0.height(Constants.height0)
            constraint1 = view1.height(Constants.height1)
            constraint2 = view2.height(Constants.height2)
            constraint3 = view3.height(Constants.height3)
            constraint4 = view4.height(Constants.height4)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, height: Constants.height0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, height: Constants.height1))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, height: Constants.height2))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, height: Constants.height3))
        XCTAssertConstraint(constraint4, expectedConstraint(view: view4, height: Constants.height4))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.height, Constants.height0)
        XCTAssertEqual(view1.frame.height, Constants.height1)
        XCTAssertEqual(view2.frame.height, Constants.height2)
        XCTAssertEqual(view3.frame.height, Constants.height3)
        XCTAssertEqual(view4.frame.height, Constants.height4)
    }

    func testConstrain_WithSixHeightConstraint_ShouldSupportAbsoluteHeight() {

        constrain(view0, view1, view2, view3, view4, view5) { view0, view1, view2, view3, view4, view5 in
            constraint0 = view0.height(Constants.height0)
            constraint1 = view1.height(Constants.height1)
            constraint2 = view2.height(Constants.height2)
            constraint3 = view3.height(Constants.height3)
            constraint4 = view4.height(Constants.height4)
            constraint5 = view5.height(Constants.height5)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, height: Constants.height0))
        XCTAssertConstraint(constraint1, expectedConstraint(view: view1, height: Constants.height1))
        XCTAssertConstraint(constraint2, expectedConstraint(view: view2, height: Constants.height2))
        XCTAssertConstraint(constraint3, expectedConstraint(view: view3, height: Constants.height3))
        XCTAssertConstraint(constraint4, expectedConstraint(view: view4, height: Constants.height4))
        XCTAssertConstraint(constraint5, expectedConstraint(view: view5, height: Constants.height5))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.height, Constants.height0)
        XCTAssertEqual(view1.frame.height, Constants.height1)
        XCTAssertEqual(view2.frame.height, Constants.height2)
        XCTAssertEqual(view3.frame.height, Constants.height3)
        XCTAssertEqual(view4.frame.height, Constants.height4)
        XCTAssertEqual(view5.frame.height, Constants.height5)
    }

    func testConstrain_WithHeightConstraint_ShouldSupportRelativeHeight() {

        constrain(host, view0) { host, view0 in
            constraint0 = view0.height(to: host)
        }

        XCTAssertConstraint(constraint0, expectedConstraint(view: view0, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.height, host.frame.height)
    }

    func testConstrain_WithHeightConstraint_ShouldSupportRelativeEquality() {

        view1.translatesAutoresizingMaskIntoConstraints = false
        view2.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.height(Constants.height0)
            constraints = [view0, view1, view2].equalHeight()
        }

        let expected = [
            expectedConstraint(view: view0, to: view1),
            expectedConstraint(view: view0, to: view2)
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.height, Constants.height0)
        XCTAssertEqual(view0.frame.height, view1.frame.height)
        XCTAssertEqual(view0.frame.height, view2.frame.height)
    }
}

private extension HeightConstrainableProxyTestCase {

    func expectedConstraint(view: UIView, height: CGFloat) -> NSLayoutConstraint {

        NSLayoutConstraint(
            item: view,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1,
            constant: height,
            priority: .required,
            active: true
        )
    }

    func expectedConstraint(view: UIView, to host: UIView) -> NSLayoutConstraint {

        NSLayoutConstraint(
            item: view,
            attribute: .height,
            relatedBy: .equal,
            toItem: host,
            attribute: .height,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )
    }
}

private enum Constants {

    static let height0: CGFloat = 100
    static let height1: CGFloat = 200
    static let height2: CGFloat = 300
    static let height3: CGFloat = 400
    static let height4: CGFloat = 500
    static let height5: CGFloat = 600
}
