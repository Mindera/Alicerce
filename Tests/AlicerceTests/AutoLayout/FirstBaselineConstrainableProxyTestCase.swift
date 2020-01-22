import XCTest
@testable import Alicerce

final class FirstBaselineConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithFirstBaselineConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view in
            constraint = view.firstBaseline(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .firstBaseline,
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

    func testConstrain_WithFirstBaselineToTopConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view in
            constraint = view.firstBaselineToTop(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .firstBaseline,
            relatedBy: .equal,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }

    func testConstrain_WithFirstBaselineToBottomConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view in
            constraint = view.firstBaselineToBottom(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .firstBaseline,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }
}
