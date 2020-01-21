import XCTest
@testable import Alicerce

final class LeadingTrailingConstrainableProxyTestCase: BaseConstrainableProxyTestCase {

    override func setUp() {

        super.setUp()

        view0.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view0.heightAnchor.constraint(equalToConstant: 100).isActive = true

        view1.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view1.heightAnchor.constraint(equalToConstant: 100).isActive = true

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
}
