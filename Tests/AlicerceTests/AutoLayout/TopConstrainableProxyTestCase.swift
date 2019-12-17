import XCTest
@testable import Alicerce

final class TopConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithTopConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.top(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .top,
            relatedBy: .equal,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.minY, 0)
    }

    func testConstrain_withTopConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint1 = view.top(to: host, relation: .equalOrLess)
            constraint2 = view.top(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view!,
            attribute: .top,
            relatedBy: .lessThanOrEqual,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint1, expected1)

        let expected2 = NSLayoutConstraint(
            item: view!,
            attribute: .top,
            relatedBy: .greaterThanOrEqual,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint2, expected2)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.minY, 0)
    }

    func testConstrain_WithTopConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.top(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .top,
            relatedBy: .equal,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.minY, 100)
    }

    func testConstrain_WithTopConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.top(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .top,
            relatedBy: .equal,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: -100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.minY, -100)
    }

    func testConstrain_WithTopConstraint_ShouldSupportBottomAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.topToBottom(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .top,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.minY, 500)
    }

    func testConstrain_WithTopConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.top(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .top,
            relatedBy: .equal,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 0,
            priority: .init(666),
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }
}
