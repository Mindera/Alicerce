import XCTest
@testable import Alicerce

class AspectRatioConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    private(set) var constraints0: NSLayoutConstraint!

    func testConstrain_WithAbsoluteWidthAndAspectRatioConstraint_ShouldSupportRelativeSize() {

        constrain(view0) { view0 in
            view0.width(1920)
            constraints0 = view0.aspectRatio(16/9)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .width,
            relatedBy: .equal,
            toItem: view0!,
            attribute: .height,
            multiplier: 16/9,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraints0, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, Constants.size0)
    }

    func testConstrain_WithRelativeHeightAndAspectRatioConstraint_ShouldSupportRelativeSize() {

        constrain(view0, host) { view0, host in
            view0.top(to: host, offset: 100)
            view0.bottom(to: host)
            constraints0 = view0.aspectRatio(0.5)
        }

        let expected0 = NSLayoutConstraint(
            item: view0!,
            attribute: .width,
            relatedBy: .equal,
            toItem: view0!,
            attribute: .height,
            multiplier: 0.5,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraints0, expected0)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.size, Constants.size1)
    }
}

private enum Constants {

    static let size0 = CGSize(width: 1920, height: 1080)
    static let size1 = CGSize(width: 200, height: 400)
}
