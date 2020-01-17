import XCTest
@testable import Alicerce

class SizeConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

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

    func testConstrain_WithOneSizeConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0) { view0 in
            constraints0 = view0.size(Constants.size0)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, size: Constants.size0))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, Constants.size0)
    }

    func testConstrain_WithTwoSizeConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1) { view0, view1 in
            constraints0 = view0.size(Constants.size0)
            constraints1 = view1.size(Constants.size1)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, size: Constants.size0))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, size: Constants.size1))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, Constants.size0)
        XCTAssertEqual(view1.frame.size, Constants.size1)
    }

    func testConstrain_WithThreeSizeConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1, view2) { view0, view1, view2 in
            constraints0 = view0.size(Constants.size0)
            constraints1 = view1.size(Constants.size1)
            constraints2 = view2.size(Constants.size2)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, size: Constants.size0))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, size: Constants.size1))
        XCTAssertConstraints(constraints2, expectedConstraints(view: view2, size: Constants.size2))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, Constants.size0)
        XCTAssertEqual(view1.frame.size, Constants.size1)
        XCTAssertEqual(view2.frame.size, Constants.size2)
    }

    func testConstrain_WithFourSizeConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1, view2, view3) { view0, view1, view2, view3 in
            constraints0 = view0.size(Constants.size0)
            constraints1 = view1.size(Constants.size1)
            constraints2 = view2.size(Constants.size2)
            constraints3 = view3.size(Constants.size3)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, size: Constants.size0))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, size: Constants.size1))
        XCTAssertConstraints(constraints2, expectedConstraints(view: view2, size: Constants.size2))
        XCTAssertConstraints(constraints3, expectedConstraints(view: view3, size: Constants.size3))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, Constants.size0)
        XCTAssertEqual(view1.frame.size, Constants.size1)
        XCTAssertEqual(view2.frame.size, Constants.size2)
        XCTAssertEqual(view3.frame.size, Constants.size3)
    }

    func testConstrain_WithFiveSizeConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1, view2, view3, view4) { view0, view1, view2, view3, view4 in
            constraints0 = view0.size(Constants.size0)
            constraints1 = view1.size(Constants.size1)
            constraints2 = view2.size(Constants.size2)
            constraints3 = view3.size(Constants.size3)
            constraints4 = view4.size(Constants.size4)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, size: Constants.size0))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, size: Constants.size1))
        XCTAssertConstraints(constraints2, expectedConstraints(view: view2, size: Constants.size2))
        XCTAssertConstraints(constraints3, expectedConstraints(view: view3, size: Constants.size3))
        XCTAssertConstraints(constraints4, expectedConstraints(view: view4, size: Constants.size4))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, Constants.size0)
        XCTAssertEqual(view1.frame.size, Constants.size1)
        XCTAssertEqual(view2.frame.size, Constants.size2)
        XCTAssertEqual(view3.frame.size, Constants.size3)
        XCTAssertEqual(view4.frame.size, Constants.size4)
    }

    func testConstrain_WithSixSizeConstraint_ShouldSupportAbsoluteWidth() {

        constrain(view0, view1, view2, view3, view4, view5) { view0, view1, view2, view3, view4, view5 in
            constraints0 = view0.size(Constants.size0)
            constraints1 = view1.size(Constants.size1)
            constraints2 = view2.size(Constants.size2)
            constraints3 = view3.size(Constants.size3)
            constraints4 = view4.size(Constants.size4)
            constraints5 = view5.size(Constants.size5)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, size: Constants.size0))
        XCTAssertConstraints(constraints1, expectedConstraints(view: view1, size: Constants.size1))
        XCTAssertConstraints(constraints2, expectedConstraints(view: view2, size: Constants.size2))
        XCTAssertConstraints(constraints3, expectedConstraints(view: view3, size: Constants.size3))
        XCTAssertConstraints(constraints4, expectedConstraints(view: view4, size: Constants.size4))
        XCTAssertConstraints(constraints5, expectedConstraints(view: view5, size: Constants.size5))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, Constants.size0)
        XCTAssertEqual(view1.frame.size, Constants.size1)
        XCTAssertEqual(view2.frame.size, Constants.size2)
        XCTAssertEqual(view3.frame.size, Constants.size3)
        XCTAssertEqual(view4.frame.size, Constants.size4)
        XCTAssertEqual(view5.frame.size, Constants.size5)
    }

    func testConstrain_WithSizeConstraint_ShouldSupportRelativeWidth() {

        constrain(host, view0) { host, view0 in
            constraints0 = view0.size(to: host)
        }

        XCTAssertConstraints(constraints0, expectedConstraints(view: view0, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, host.frame.size)
    }
}

private extension SizeConstrainableProxyTestCase {

    private func expectedConstraints(view: UIView, size: CGSize) -> [NSLayoutConstraint] {

        let width = NSLayoutConstraint(
            item: view,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .width,
            multiplier: 1,
            constant: size.width,
            priority: .required,
            active: true
        )

        let height = NSLayoutConstraint(
            item: view,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1,
            constant: size.height,
            priority: .required,
            active: true
        )

        return [width, height]
    }

    private func expectedConstraints(view: UIView, to host: UIView) -> [NSLayoutConstraint] {

        let width = NSLayoutConstraint(
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

        let height = NSLayoutConstraint(
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

        return [width, height]
    }
}

private enum Constants {

    static let size0 = CGSize(width: 100, height: 100)
    static let size1 = CGSize(width: 200, height: 200)
    static let size2 = CGSize(width: 300, height: 300)
    static let size3 = CGSize(width: 400, height: 400)
    static let size4 = CGSize(width: 500, height: 500)
    static let size5 = CGSize(width: 600, height: 600)
}
