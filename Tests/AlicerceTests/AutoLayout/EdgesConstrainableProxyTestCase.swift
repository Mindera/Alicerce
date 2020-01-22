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

        let expected = [
            NSLayoutConstraint(
                item: view!,
                attribute: .top,
                relatedBy: .equal,
                toItem: host,
                attribute: .top,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: host,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: host,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
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
        ]

        XCTAssertEdgesConstraints(constraints, expected)

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

        let expected1 = [
            NSLayoutConstraint(
                item: view!,
                attribute: .top,
                relatedBy: .lessThanOrEqual,
                toItem: host,
                attribute: .top,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .leading,
                relatedBy: .lessThanOrEqual,
                toItem: host,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .bottom,
                relatedBy: .lessThanOrEqual,
                toItem: host,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
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
        ]

        XCTAssertEdgesConstraints(constraints1, expected1)

        let expected2 = [
            NSLayoutConstraint(
                item: view!,
                attribute: .top,
                relatedBy: .greaterThanOrEqual,
                toItem: host,
                attribute: .top,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .leading,
                relatedBy: .greaterThanOrEqual,
                toItem: host,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .bottom,
                relatedBy: .greaterThanOrEqual,
                toItem: host,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
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
        ]

        XCTAssertEdgesConstraints(constraints2, expected2)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame, host.frame)
    }

    func testConstrain_WithEdgesConstraints_ShouldSupportInsets() {

        let insets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)

        var constraints: [NSLayoutConstraint]!
        constrain(host, view) { host, view in
            constraints = view.edges(to: host, insets: insets)
        }

        let expected = [
            NSLayoutConstraint(
                item: view!,
                attribute: .top,
                relatedBy: .equal,
                toItem: host,
                attribute: .top,
                multiplier: 1,
                constant: 10,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: host,
                attribute: .leading,
                multiplier: 1,
                constant: 20,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: host,
                attribute: .bottom,
                multiplier: 1,
                constant: -30,
                priority: .required,
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: host,
                attribute: .trailing,
                multiplier: 1,
                constant: -40,
                priority: .required,
                active: true
            )
        ]

        XCTAssertEdgesConstraints(constraints, expected)

        host.layoutIfNeeded()

        XCTAssertEqual(view.frame, host.frame.inset(by: insets))
    }

    func testConstrain_WithEdgesConstraints_ShouldSupportCustomPriority() {

        var constraints: [NSLayoutConstraint]!
        constrain(host, view) { host, view in
            constraints = view.edges(to: host, priority: .init(666))
        }

        let expected = [
            NSLayoutConstraint(
                item: view!,
                attribute: .top,
                relatedBy: .equal,
                toItem: host,
                attribute: .top,
                multiplier: 1,
                constant: 0,
                priority: .init(666),
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: host,
                attribute: .leading,
                multiplier: 1,
                constant: 0,
                priority: .init(666),
                active: true
            ),
            NSLayoutConstraint(
                item: view!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: host,
                attribute: .bottom,
                multiplier: 1,
                constant: 0,
                priority: .init(666),
                active: true
            ),
            NSLayoutConstraint(
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
        ]

        XCTAssertEdgesConstraints(constraints, expected)
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
