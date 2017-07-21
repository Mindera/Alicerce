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

    func testHexString_WithBaseColors_ItShouldReturnCorrectHexColor() {

        let hexRed = UIColor.red.hexString
        let hexGreen = UIColor.green.hexString
        let hexBlue = UIColor.blue.hexString

        XCTAssertEqual(hexRed, "#ff0000")
        XCTAssertEqual(hexGreen, "#00ff00")
        XCTAssertEqual(hexBlue, "#0000ff")
    }

    func testHexString_WithAlphaColors_ItShouldReturnCorrectHexColor() {

        let hexOpaque = UIColor(white: 1.0, alpha: 1.0).hexStringWithAlpha
        let hexSemi = UIColor(white: 1.0, alpha: 0.5).hexStringWithAlpha
        let hexTransparent = UIColor(white: 1.0, alpha: 0.0).hexStringWithAlpha

        XCTAssertEqual(hexOpaque, "#ffffffff")
        XCTAssertEqual(hexSemi, "#7fffffff")
        XCTAssertEqual(hexTransparent, "#00ffffff")
    }
}
