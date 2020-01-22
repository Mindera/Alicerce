import XCTest
@testable import Alicerce

final class LastBaselineConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithLastBaselineConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view in
            constraint = view.lastBaseline(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .lastBaseline,
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

    func testConstrain_WithLastBaselineToTopConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view in
            constraint = view.lastBaselineToTop(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .lastBaseline,
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

    func testConstrain_WithLastBaselineToBottomConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view in
            constraint = view.lastBaselineToBottom(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .lastBaseline,
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
