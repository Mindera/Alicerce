import XCTest
@testable import Alicerce

final class LastBaselineConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.translatesAutoresizingMaskIntoConstraints = false
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

    func testConstrain_WithLastBaselineConstraintAndTwoConstraintGroups_ShouldReturnCorrectIsActiveConstraint() {

        var constraint0: NSLayoutConstraint!
        var constraint1: NSLayoutConstraint!

        let constraintGroup0 = constrain(host, view0, activate: false) { host, view0 in
            constraint0 = view0.lastBaseline(to: host)
        }

        let constraintGroup1 = constrain(host, view0, activate: false) { host, view0 in
            constraint1 = view0.lastBaseline(to: host, offset: -100)
        }

        let expected = [
            NSLayoutConstraint(
                item: view0!,
                attribute: .lastBaseline,
                relatedBy: .equal,
                toItem: host,
                attribute: .lastBaseline,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: false
            ),
            NSLayoutConstraint(
                item: view0!,
                attribute: .lastBaseline,
                relatedBy: .equal,
                toItem: host,
                attribute: .lastBaseline,
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
        XCTAssertEqual(view0.frame.maxY, host.frame.maxY)

        constraintGroup0.isActive = false
        constraintGroup1.isActive = true

        host.setNeedsLayout()
        host.layoutIfNeeded()

        XCTAssertFalse(constraintGroup0.isActive)
        XCTAssert(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.maxY, host.frame.maxY - 100)
    }
}
