import XCTest
@testable import Alicerce

final class TopBottomConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true

        view1.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view1.heightAnchor.constraint(equalToConstant: 100).isActive = true

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
}
