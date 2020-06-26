import XCTest
@testable import Alicerce

final class TopBottomConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

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

    func testConstrain_WithDistributeVerticallyConstraint_ShouldSupportRelativeEquality() {

        var constraints: [NSLayoutConstraint]!
        constrain(host, view0, view1, view2) { host, view0, view1, view2 in
            view0.top(to: host, offset: 50)
            constraints = [view0, view1, view2].distributeVertically()
        }

        let expected = [
            NSLayoutConstraint(
                item: view1!,
                attribute: .top,
                relatedBy: .equal,
                toItem: view0,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view2!,
                attribute: .top,
                relatedBy: .equal,
                toItem: view1,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            )
        ]

        XCTAssertConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view0.frame.maxY, view1.frame.minY)
        XCTAssertEqual(view1.frame.maxY, view2.frame.minY)
    }

    func testConstrain_WithDistributeVerticallyConstraintAndEmptyArray_ShouldReturnEmptyArray() {

        let constraints = [UIView.ProxyType]().distributeVertically()

        XCTAssertConstraints(constraints, [])
    }

    func testConstrain_WithDistributeVerticallyConstraintAndTwoConstraintGroups_ShouldReturnCorrectIsActiveConstraint(
    ) {

        var constraints0: [NSLayoutConstraint]!
        var constraints1: [NSLayoutConstraint]!

        let constraintGroup0 = constrain(host, view0, view1, view2, activate: false) { host, view0, view1, view2 in
            view0.leading(to: host, offset: 50)
            constraints0 = [view0, view1, view2].distributeVertically()
        }

        let constraintGroup1 = constrain(host, view0, view1, view2, activate: false) { host, view0, view1, view2 in
            view0.leading(to: host, offset: 50)
            constraints1 = [view0, view1, view2].distributeVertically(margin: 20)
        }

        let expected0 = [
            NSLayoutConstraint(
                item: view1!,
                attribute: .top,
                relatedBy: .equal,
                toItem: view0,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: false
            ),
            NSLayoutConstraint(
                item: view2!,
                attribute: .top,
                relatedBy: .equal,
                toItem: view1,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: false
            )
        ]

        let expected1 = [
            NSLayoutConstraint(
                item: view1!,
                attribute: .top,
                relatedBy: .equal,
                toItem: view0,
                attribute: .bottom,
                multiplier: 1,
                constant: 20,
                priority: .required,
                active: false
            ),
            NSLayoutConstraint(
                item: view2!,
                attribute: .top,
                relatedBy: .equal,
                toItem: view1,
                attribute: .bottom,
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
        XCTAssertEqual(view0.frame.maxY, view1.frame.minY)
        XCTAssertEqual(view1.frame.maxY, view2.frame.minY)

        constraintGroup0.isActive = false
        constraintGroup1.isActive = true

        host.setNeedsLayout()
        host.layoutIfNeeded()

        XCTAssertFalse(constraintGroup0.isActive)
        XCTAssert(constraintGroup1.isActive)
        XCTAssertEqual(view0.frame.maxY + 20, view1.frame.minY)
        XCTAssertEqual(view1.frame.maxY + 20, view2.frame.minY)
    }
}
