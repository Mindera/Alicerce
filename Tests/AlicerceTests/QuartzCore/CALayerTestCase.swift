//
//  CALayerTestCase.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 22/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
import QuartzCore
@testable import Alicerce

class CALayerTestCase: XCTestCase {

    func testSolidLayer_WithGivenColor_ShouldCreateLayerWithCorrectColor() {
        let testColor = UIColor.white

        let layer = CALayer.solidLayer(color: testColor)

        XCTAssertEqual(layer.backgroundColor, testColor.cgColor)
    }
}
