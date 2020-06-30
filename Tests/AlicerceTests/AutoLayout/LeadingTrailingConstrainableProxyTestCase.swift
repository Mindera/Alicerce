import XCTest
@testable import Alicerce

final class LeadingTrailingConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.translatesAutoresizingMaskIntoConstraints = false
        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true

        view1.translatesAutoresizingMaskIntoConstraints = false
        view1.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view1.heightAnchor.constraint(equalToConstant: 100).isActive = true

        view2.translatesAutoresizingMaskIntoConstraints = false
        view2.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view2.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    func testConstrain_WithDistributeHorizontallyConstraint_ShouldSupportRelativeEquality() {

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.leading(to: host, offset: 50)
            constraints = [view0, view1, view2].distributeHorizontally()
        }

        let expected = [
            NSLayoutConstraint(
                item: view1!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view0,
                attribute: .trailing,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view2!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view1,
                attribute: .trailing,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            )
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxX, view1.frame.minX)
        XCTAssertEqual(view1.frame.maxX, view2.frame.minX)
    }

    func testConstrain_WithDistributeHorizontallyConstraintAndEmptyArray_ShouldReturnEmptyArray() {

        let constraints = [UIView.ProxyType]().distributeHorizontally()

        XCTAssertConstraints(constraints, [])
    }

    func testConstrain_WithDistributeHorizontallyConstraintAndTwoConstraintGroups_ShouldReturnCorrectIsActiveConstraint(
    ) {

        var constraints0: [NSLayoutConstraint]!
        var constraints1: [NSLayoutConstraint]!

        let constraintGroup0 = constrain(host, view0, view1, view2, activate: false) { host, view0, view1, view2 in
            view0.leading(to: host, offset: 50)
            constraints0 = [view0, view1, view2].distributeHorizontally()
        }

        let constraintGroup1 = constrain(host, view0, view1, view2, activate: false) { host, view0, view1, view2 in
            view0.leading(to: host, offset: 50)
            constraints1 = [view0, view1, view2].distributeHorizontally(margin: 20)
        }

        let expected0 = [
            NSLayoutConstraint(
                item: view1!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view0,
                attribute: .trailing,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: false
            ),
            NSLayoutConstraint(
                item: view2!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view1,
                attribute: .trailing,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: false
            )
        ]

        let expected1 = [
            NSLayoutConstraint(
                item: view1!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view0,
                attribute: .trailing,
                multiplier: 1,
                constant: 20,
                priority: .required,
                active: false
            ),
            NSLayoutConstraint(
                item: view2!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: view1,
                attribute: .trailing,
                multiplier: 1,
                constant: 20,
                priority: .required,
                active: false
            )
        ]

        XCTAssertConstraints(constraints0, expected0)
        XCTAssertConstraints(constraints1, expected1)

        constraintGroup0.isActive = true

        host.layoutIfNeeded()

        XCTAssert(constraintGroup0.isActive)
        XCTAssertFalse(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.maxX, view1.frame.minX)
        XCTAssertEqual(view1.frame.maxX, view2.frame.minX)

        constraintGroup0.isActive = false
        constraintGroup1.isActive = true

        host.setNeedsLayout()
        host.layoutIfNeeded()

        XCTAssertFalse(constraintGroup0.isActive)
        XCTAssert(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.maxX + 20, view1.frame.minX)
        XCTAssertEqual(view1.frame.maxX + 20, view2.frame.minX)
    }
}
