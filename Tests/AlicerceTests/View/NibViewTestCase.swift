//
//  NibViewTestCase.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 20/11/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
import UIKit
@testable import Alicerce

final class TestView: UIView, NibView {}

class GenericTestView<T>: UIView, NibView {
    let t: T? = nil
}

final class SpecializedGenericTestView: GenericTestView<Int> {}

class NibViewTestCase: XCTestCase {

    func testNib_WithSimpleView_ShouldSucceed() {
        let nib = TestView.nib

        guard let _ = nib.instantiate(withOwner: self, options: nil).first as? TestView else {
            return XCTFail("failed to instantiate view from Nib")
        }
    }

    func testNib_WithSpecializedGenericView_ShouldSucceed() {
        let nib = SpecializedGenericTestView.nib

        guard let _ = nib.instantiate(withOwner: self, options: nil).first as? SpecializedGenericTestView else {
            return XCTFail("failed to instantiate view from Nib")
        }
    }
}
