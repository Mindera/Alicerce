// swiftlint:disable function_body_length

import XCTest
@testable import Alicerce

final class EdgesConstrainableProxyTestCase: XCTestCase {

    var host: UIView!
    var view: UIView!

    override func setUp() {

        host = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        view = UIView()

        host.addSubview(view)

        super.setUp()
    }

    override func tearDown() {

        view = nil
        host = nil

        super.tearDown()
    }

    func testConstrain_WithEdgesConstraints_ShouldSupportRelativeEquality() {

        var constraints: [NSLayoutConstraint]!
        constrain(host, view) { host, view in
            constraints = view.edges(to: host)
        }

        XCTAssertEdgesConstraints(constraints, expectedConstraints(view: view, to: host))

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame, host.frame)
    }

    func testConstrain_withEdgesConstraints_ShouldSupportRelativeInequalities() {

        var constraints1: [NSLayoutConstraint]!
        var constraints2: [NSLayoutConstraint]!
        constrain(host, view) { host, view in
            constraints1 = view.edges(to: host, relation: .equalOrLess)
            constraints2 = view.edges(to: host, relation: .equalOrGreater)
        }

        XCTAssertEdgesConstraints(constraints1, expectedConstraints(view: view, to: host, relation: .lessThanOrEqual))
        XCTAssertEdgesConstraints(
            constraints2,
            expectedConstraints(view: view, to: host, relation: .greaterThanOrEqual)
        )

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame, host.frame)
    }

    func testConstrain_WithEdgesConstraints_ShouldSupportInsets() {

        let insets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)

        var constraints: [NSLayoutConstraint]!
        constrain(host, view) { host, view in
            constraints = view.edges(to: host, insets: insets)
        }

        XCTAssertEdgesConstraints(constraints, expectedConstraints(view: view, to: host, constants: insets))

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame, host.frame.inset(by: insets))
    }

    func testConstrain_WithEdgesConstraints_ShouldSupportCustomPriority() {

        var constraints: [NSLayoutConstraint]!
        constrain(host, view) { host, view in
            constraints = view.edges(to: host, priority: .init(666))
        }

        XCTAssertEdgesConstraints(constraints, expectedConstraints(view: view, to: host, priority: .init(666)))
    }

    func testConstrain_WithEdgesConstraintsAndTwoConstraintGroups_ShouldReturnCorrectIsActiveConstraint() {

        var constraints0: [NSLayoutConstraint]!
        var constraints1: [NSLayoutConstraint]!

        let insets = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)

        let constraintGroup0 = constrain(host, view, activate: false) { host, view in
            constraints0 = view.edges(to: host)
        }

        let constraintGroup1 = constrain(host, view, activate: false) { host, view in
            constraints1 = view.edges(to: host, insets: insets)
        }

        XCTAssertEdgesConstraints(constraints0, expectedConstraints(view: view, to: host, active: false))
        XCTAssertEdgesConstraints(
            constraints1,
            expectedConstraints(view: view, to: host, constants: insets, active: false)
        )

        constraintGroup0.isActive = true

        host.layoutIfNeeded()

        XCTAssert(constraintGroup0.isActive)
        XCTAssertFalse(constraintGroup1.isActive)
        XCTAssertEqual(view.frame, host.frame)

        constraintGroup0.isActive = false
        constraintGroup1.isActive = true

        host.setNeedsLayout()
        host.layoutIfNeeded()

        XCTAssertFalse(constraintGroup0.isActive)
        XCTAssert(constraintGroup1.isActive)
        XCTAssertEqual(view.frame, host.frame.inset(by: insets))
    }
}

// MARK: - XCTAssertEdgesConstraints

private func XCTAssertEdgesConstraints(
    _ constraints1: [NSLayoutConstraint],
    _ constraints2: [NSLayoutConstraint],
    file: StaticString = #file,
    line: UInt = #line
) {

    guard constraints1.count == 4 else {
        XCTFail("Invalid number of constraints.", file: file, line: line)
        return
    }

    guard constraints1.count == constraints2.count else {
        XCTFail("Arrays count doesn't match.", file: file, line: line)
        return
    }

    if let top = extract(attribute: .top, from: constraints1, constraints2) {
        XCTAssertConstraint(top.left, top.right, file: file, line: line)
    } else {
        XCTFail("Missing top constraints.", file: file, line: line)
    }

    if let bottom = extract(attribute: .bottom, from: constraints1, constraints2) {
        XCTAssertConstraint(bottom.left, bottom.right, file: file, line: line)
    } else {
        XCTFail("Missing bottom constraints.", file: file, line: line)
    }

    if let leading = extract(attribute: .leading, from: constraints1, constraints2) {
        XCTAssertConstraint(leading.left, leading.right, file: file, line: line)
    } else {
        XCTFail("Missing leading constraints.", file: file, line: line)
    }

    if let trailing = extract(attribute: .trailing, from: constraints1, constraints2) {
        XCTAssertConstraint(trailing.left, trailing.right, file: file, line: line)
    } else {
        XCTFail("Missing trailing constraints.", file: file, line: line)
    }
}

private func extract(
    attribute: NSLayoutConstraint.Attribute,
    from left: [NSLayoutConstraint],
    _ right: [NSLayoutConstraint]
) -> (left: NSLayoutConstraint, right: NSLayoutConstraint)? {

    guard
        let left = left.first(where: { $0.firstAttribute == attribute }),
        let right = right.first(where: { $0.firstAttribute == attribute })
    else {
        return nil
    }

    return (left, right)
}

// MARK: - Extensions

private extension EdgesConstrainableProxyTestCase {

    private func expectedConstraints(
        view: UIView,
        to host: UIView,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        constants: UIEdgeInsets = .zero,
        active: Bool = true
    ) -> [NSLayoutConstraint] {

        return [
            NSLayoutConstraint(
                item: view,
                attribute: .top,
                relatedBy: relation,
                toItem: host,
                attribute: .top,
                multiplier: 1,
                constant: constants.top,
                priority: priority,
                active: active
            ),
            NSLayoutConstraint(
                item: view,
                attribute: .leading,
                relatedBy: relation,
                toItem: host,
                attribute: .leading,
                multiplier: 1,
                constant: constants.left,
                priority: priority,
                active: active
            ),
            NSLayoutConstraint(
                item: view,
                attribute: .bottom,
                relatedBy: relation,
                toItem: host,
                attribute: .bottom,
                multiplier: 1,
                constant: -constants.bottom,
                priority: priority,
                active: active
            ),
            NSLayoutConstraint(
                item: view,
                attribute: .trailing,
                relatedBy: relation,
                toItem: host,
                attribute: .trailing,
                multiplier: 1,
                constant: -constants.right,
                priority: priority,
                active: active
            )
        ]
    }
}
