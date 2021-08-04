import XCTest

func XCTAssertConstraint(
    _ constraint1: NSLayoutConstraint,
    _ constraint2: NSLayoutConstraint,
    file: StaticString = #file,
    line: UInt = #line
) {

    if let item = constraint1.firstItem as? UIView, item === constraint2.firstItem {
        XCTAssertFalse(item.translatesAutoresizingMaskIntoConstraints, file: file, line: line)
    }

    XCTAssertIdentical(constraint1.firstItem, constraint2.firstItem, file: file, line: line)
    XCTAssertEqual(constraint1.firstAttribute, constraint2.firstAttribute, file: file, line: line)

    XCTAssertIdentical(constraint1.secondItem, constraint2.secondItem, file: file, line: line)
    XCTAssertEqual(constraint1.secondAttribute, constraint2.secondAttribute, file: file, line: line)

    XCTAssertEqual(constraint1.relation, constraint2.relation, file: file, line: line)

    XCTAssertEqual(constraint1.multiplier, constraint2.multiplier, file: file, line: line)
    XCTAssertEqual(constraint1.constant, constraint2.constant, file: file, line: line)

    XCTAssertEqual(constraint1.isActive, constraint2.isActive, file: file, line: line)
    XCTAssertEqual(constraint1.priority, constraint2.priority, file: file, line: line)
}

func XCTAssertConstraints(
    _ constraints1: [NSLayoutConstraint],
    _ constraints2: [NSLayoutConstraint],
    file: StaticString = #file,
    line: UInt = #line
) {

    zip(constraints1, constraints2).forEach { constraint1, constraint2 in

        if let item = constraint1.firstItem as? UIView, item === constraint2.firstItem {
            XCTAssertFalse(item.translatesAutoresizingMaskIntoConstraints, file: file, line: line)
        }

        XCTAssertIdentical(constraint1.firstItem, constraint2.firstItem, file: file, line: line)
        XCTAssertEqual(constraint1.firstAttribute, constraint2.firstAttribute, file: file, line: line)

        XCTAssertIdentical(constraint1.secondItem, constraint2.secondItem, file: file, line: line)
        XCTAssertEqual(constraint1.secondAttribute, constraint2.secondAttribute, file: file, line: line)

        XCTAssertEqual(constraint1.relation, constraint2.relation, file: file, line: line)

        XCTAssertEqual(constraint1.multiplier, constraint2.multiplier, file: file, line: line)
        XCTAssertEqual(constraint1.constant, constraint2.constant, file: file, line: line)

        XCTAssertEqual(constraint1.isActive, constraint2.isActive, file: file, line: line)
        XCTAssertEqual(constraint1.priority, constraint2.priority, file: file, line: line)
    }
}
