//
//  UIColorTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 18/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
import UIKit

@testable import Alicerce

final class UIColorTestCase: XCTestCase {

    func testHex_When16BitsRGBColorProvided_ItShouldReturnAValidUIColor() {
        let colorHex = "#ffffff"

        let color = UIColor(hex: colorHex)

        let ciColor = CIColor(color: color)

        XCTAssertEqual(ciColor.red, 1.0)
        XCTAssertEqual(ciColor.green, 1.0)
        XCTAssertEqual(ciColor.blue, 1.0)
        XCTAssertEqual(ciColor.alpha, 1.0)
    }

    func testHex_When32BitsRGBColorProvided_ItShouldReturnAValidUIColor() {
        let colorHex = "#ffffff00"

        let color = UIColor(hex: colorHex)

        let ciColor = CIColor(color: color)

        XCTAssertEqual(ciColor.red, 1.0)
        XCTAssertEqual(ciColor.green, 1.0)
        XCTAssertEqual(ciColor.blue, 1.0)
        XCTAssertEqual(ciColor.alpha, 0.0)
    }
}
