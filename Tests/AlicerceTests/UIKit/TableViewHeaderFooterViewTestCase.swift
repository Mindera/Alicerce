//
//  TableViewHeaderFooterViewTestCase.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 16/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

final class MockTableViewHeaderFooterView: TableViewHeaderFooterView {

    private(set) var setUpSubviewsCallCount = 0
    private(set) var setUpConstraintsCallCount = 0

    override func setUpSubviews() {
        super.setUpSubviews()
        setUpSubviewsCallCount += 1
    }

    override func setUpConstraints() {
        super.setUpConstraints()
        setUpConstraintsCallCount += 1
    }
}

class TableViewHeaderFooterViewTestCase: XCTestCase {

    func testInit_WithReuseIdentifier_ShouldInvokeSetUpMethods() {

        let cell = MockTableViewHeaderFooterView(reuseIdentifier: nil)

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)
    }

    func testInit_WithCoder_ShouldInvokeSetUpMethods() {

        guard let cell: MockTableViewHeaderFooterView = UIView.instantiateFromNib(withOwner: self) else {
            return XCTFail("failed to load view from nib!")
        }

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)
    }
}
