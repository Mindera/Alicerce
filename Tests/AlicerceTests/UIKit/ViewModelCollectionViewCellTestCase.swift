//
//  ViewModelCollectionViewCellTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 26/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class MockViewModelCollectionViewCell: ViewModelCollectionViewCell<MockReusableViewModelView> {

    private(set) var setUpSubviewsCallCount = 0
    private(set) var setUpConstraintsCallCount = 0
    private(set) var setUpBindingsCallCount = 0

    override func setUpSubviews() {
        super.setUpSubviews()
        setUpSubviewsCallCount += 1
    }

    override func setUpConstraints() {
        super.setUpConstraints()
        setUpConstraintsCallCount += 1
    }

    override func setUpBindings() {
        super.setUpBindings()
        setUpBindingsCallCount += 1
    }
}

final class ViewModelCollectionViewCellTestCase: XCTestCase {

    func testInit_WithFrame_ShouldInvokeSetUpMethods() {

        let cell = MockViewModelCollectionViewCell()

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)

        XCTAssertNil(cell.viewModel)

        let viewModel = MockReusableViewModelView()
        cell.viewModel = viewModel

        XCTAssertNotNil(cell.viewModel)
        XCTAssertEqual(cell.viewModel, viewModel)
        XCTAssertEqual(cell.setUpBindingsCallCount, 1)
    }

    func testInit_WithCoder_ShouldInvokeSetUpMethods() {

        guard let cell: MockViewModelCollectionViewCell = UIView.instantiateFromNib(withOwner: self) else {
            return XCTFail("failed to load view from nib!")
        }

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)

        XCTAssertNil(cell.viewModel)

        let viewModel = MockReusableViewModelView()
        cell.viewModel = viewModel

        XCTAssertNotNil(cell.viewModel)
        XCTAssertEqual(cell.viewModel, viewModel)
        XCTAssertEqual(cell.setUpBindingsCallCount, 1)
    }
}
