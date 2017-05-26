//
//  ViewModelTableViewHeaderFooterViewTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 26/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

fileprivate final class MockViewModelTableViewHeaderFooterView<ViewModel>:
ViewModelTableViewHeaderFooterView<ViewModel> {

    private(set) var setUpSubviewsCallCount = 0
    private(set) var setUpConstraintsCallCount = 0
    private(set) var setUpBindingCallCount = 0

    override func setUpSubviews() { setUpSubviewsCallCount += 1 }

    override func setUpConstraints() { setUpConstraintsCallCount += 1 }

    override func setUpBindings() { setUpBindingCallCount += 1 }
}

final class ViewModelTableViewHeaderFooterViewTestCase: XCTestCase {
    func testInit_WithFrame_ShouldInvokeSetUpMethods() {

        let cell = MockViewModelTableViewHeaderFooterView<MockReusableViewModelView>()

        XCTAssertEqual(cell.setUpSubviewsCallCount, 1)
        XCTAssertEqual(cell.setUpConstraintsCallCount, 1)

        let viewModel = MockReusableViewModelView()
        cell.viewModel = viewModel

        XCTAssertEqual(cell.viewModel, viewModel)
        XCTAssertEqual(cell.setUpBindingCallCount, 1)
    }
}
