import XCTest
@testable import Alicerce

final class LeadingConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leading(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 0)
    }

    func testConstrain_withLeadingConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint1 = view0.leading(to: host, relation: .equalOrLess)
            constraint2 = view0.leading(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .lessThanOrEqual,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint1, expected1)

        let expected2 = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .greaterThanOrEqual,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint2, expected2)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 0)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leading(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 100)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leading(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: -100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, -100)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportTrailingAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leadingToTrailing(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .trailing,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 500)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportCenterXAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leadingToCenterX(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .centerX,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, 250)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view0) { host, view0 in
            constraint = view0.leading(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view0!,
            attribute: .leading,
            relatedBy: .equal,
            toItem: host,
            attribute: .leading,
            multiplier: 1,
            constant: 0,
            priority: .init(666),
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }

    func testConstrain_WithAlignLeadingConstraint_ShouldSupportRelativeEquality() {

        view1.translatesAutoresizingMaskIntoConstraints = false
        view2.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.leading(to: host, offset: 50)
            constraints = [view0, view1, view2].alignLeading()
        }

        let expected = [
            NSLayoutConstraint(
                item: view0!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view1,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view0!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view2,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            )
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.minX, view1.frame.minX)
        XCTAssertEqual(view0.frame.minX, view2.frame.minX)
    }
}
