import XCTest
@testable import Alicerce

final class LeadingConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.leading(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view!,
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

        XCTAssertEqual(view.frame.minX, 0)
    }

    func testConstrain_withLeadingConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint1 = view.leading(to: host, relation: .equalOrLess)
            constraint2 = view.leading(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view!,
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
            item: view!,
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

        XCTAssertEqual(view.frame.minX, 0)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.leading(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view!,
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

        XCTAssertEqual(view.frame.minX, 100)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.leading(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view!,
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

        XCTAssertEqual(view.frame.minX, -100)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportTrailingAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.leadingToTrailing(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view!,
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

        XCTAssertEqual(view.frame.minX, 500)
    }

    func testConstrain_WithLeadingConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.leading(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view!,
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
}
