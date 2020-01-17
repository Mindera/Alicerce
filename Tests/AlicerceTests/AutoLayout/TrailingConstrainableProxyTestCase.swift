import XCTest
@testable import Alicerce

final class TrailingConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.trailing(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxX, host.frame.maxX)
    }

    func testConstrain_withTrailingConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint1 = view0.trailing(to: host, relation: .equalOrLess)
            constraint2 = view0.trailing(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view0!,
            attribute: .trailing,
            relatedBy: .lessThanOrEqual,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint1, expected1)

        let expected2 = NSLayoutConstraint(
            item: view0!,
            attribute: .trailing,
            relatedBy: .greaterThanOrEqual,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint2, expected2)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxX, 500)
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.trailing(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: 100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxX, 500 + 100)
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.trailing(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: -100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxX, 500 - 100)
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportLeadingAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.trailingToLeading(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxX, 0)
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportCenterXAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.trailingToCenterX(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: host,
            attribute: .centerX,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxX, 250)
    }


    func testConstrain_WithTrailingConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.trailing(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: 0,
            priority: .init(666),
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }

    func testConstrain_WithAlignTrailingConstraint_ShouldSupportRelativeEquality() {

        var constraints: [NSLayoutConstraint]!

        view1.translatesAutoresizingMaskIntoConstraints = false
        view2.translatesAutoresizingMaskIntoConstraints = false

        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.trailing(to: host, offset: -50)
            constraints = [view0, view1, view2].alignTrailing()
        }

        let expected = [
            NSLayoutConstraint(
                item: view0!,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: view1,
                attribute: .trailing,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view0!,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: view2,
                attribute: .trailing,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            )
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxX, view1.frame.maxX)
        XCTAssertEqual(view0.frame.maxX, view2.frame.maxX)
    }
}
