import XCTest
@testable import Alicerce

final class BottomConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithBottomConstraint_ShouldSupportRelativeEquality() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.bottom(to: host)
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.maxY, 500)
    }

    func testConstrain_withBottomConstraint_ShouldSupportRelativeInequalities() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint1 = view.bottom(to: host, relation: .equalOrLess)
            constraint2 = view.bottom(to: host, relation: .equalOrGreater)
        }

        let expected1 = NSLayoutConstraint(
            item: view!,
            attribute: .bottom,
            relatedBy: .lessThanOrEqual,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint1, expected1)

        let expected2 = NSLayoutConstraint(
            item: view!,
            attribute: .bottom,
            relatedBy: .greaterThanOrEqual,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint2, expected2)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.maxY, 500)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportPositiveOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.bottom(to: host, offset: 100)
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.maxY, 500 + 100)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportNegativeOffset() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.bottom(to: host, offset: -100)
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: -100,
            priority: .required,
            active: true
        )

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.maxY, 500 - 100)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportTopAttribute() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.bottomToTop(of: host)
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .top,
            multiplier: 1,
            constant: 0,
            priority: .required,
            active: true)

        XCTAssertConstraint(constraint, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame.maxY, 0)
    }

    func testConstrain_WithBottomConstraint_ShouldSupportCustomPriority() {

        var constraint: NSLayoutConstraint!
        constrain(host, view) { host, view in
            constraint = view.bottom(to: host, priority: .init(666))
        }

        let expected = NSLayoutConstraint(
            item: view!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: host,
            attribute: .bottom,
            multiplier: 1,
            constant: 0,
            priority: .init(666),
            active: true
        )

        XCTAssertConstraint(constraint, expected)
    }
}
