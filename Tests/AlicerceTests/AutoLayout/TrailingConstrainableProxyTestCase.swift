import XCTest
@testable import Alicerce

final class TrailingConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.trailing(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view!,
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

        XCTAssertEqual(view.frame.maxX, 500)
    }

    func testConstrain_withTrailingConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint1 = view.trailing(to: host, relation: .equalOrLess)
            constraint2 = view.trailing(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view!,
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
            item: view!,
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

        XCTAssertEqual(view.frame.maxX, 500)
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.trailing(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view!,
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

        XCTAssertEqual(view.frame.maxX, 500 + 100)
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.trailing(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view!,
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

        XCTAssertEqual(view.frame.maxX, 500 - 100)
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportLeadingAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.trailingToLeading(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view!,
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

        XCTAssertEqual(view.frame.maxX, 0)
    }

    func testConstrain_WithTrailingConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.trailing(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view!,
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
}
