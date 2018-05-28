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
        let colorHex = "#00ffffff"

        let color = UIColor(hex: colorHex)

        let ciColor = CIColor(color: color)

        XCTAssertEqual(ciColor.red, 1.0)
        XCTAssertEqual(ciColor.green, 1.0)
        XCTAssertEqual(ciColor.blue, 1.0)
        XCTAssertEqual(ciColor.alpha, 0.0)
    }

    func testHexToColorToHex_WithBaseColors_ShouldGiveSameResults() {

        let hexRed = UIColor.red.hexString
        let hexGreen = UIColor.green.hexString
        let hexBlue = UIColor.blue.hexString

        XCTAssertEqual(hexRed, "#ff0000")
        XCTAssertEqual(hexGreen, "#00ff00")
        XCTAssertEqual(hexBlue, "#0000ff")

        let ciRed = CIColor(color: UIColor(hex: hexRed))
        XCTAssertEqual(ciRed.red, 1.0)
        XCTAssertEqual(ciRed.green, 0.0)
        XCTAssertEqual(ciRed.blue, 0.0)
        XCTAssertEqual(ciRed.alpha, 1.0)

        let ciGreen = CIColor(color: UIColor(hex: hexGreen))
        XCTAssertEqual(ciGreen.red, 0.0)
        XCTAssertEqual(ciGreen.green, 1.0)
        XCTAssertEqual(ciGreen.blue, 0.0)
        XCTAssertEqual(ciGreen.alpha, 1.0)

        let ciBlue = CIColor(color: UIColor(hex: hexBlue))
        XCTAssertEqual(ciBlue.red, 0.0)
        XCTAssertEqual(ciBlue.green, 0.0)
        XCTAssertEqual(ciBlue.blue, 1.0)
        XCTAssertEqual(ciBlue.alpha, 1.0)
    }

    func testHexToColorToHex_WithAlphaColors_ShouldGiveSameResults() {

        let hexOpaque = UIColor(white: 1.0, alpha: 1.0).hexStringWithAlpha
        let hexSemi = UIColor(white: 1.0, alpha: 0.5).hexStringWithAlpha
        let hexTransparent = UIColor(white: 1.0, alpha: 0.0).hexStringWithAlpha

        XCTAssertEqual(hexOpaque, "#ffffffff")
        XCTAssertEqual(hexSemi, "#7fffffff")
        XCTAssertEqual(hexTransparent, "#00ffffff")

        let colorOpaque = UIColor(hex: hexOpaque)
        let colorSemi = UIColor(hex: hexSemi)
        let colorTransparent = UIColor(hex: hexTransparent)

        let ciOpaqueColor = CIColor(color: colorOpaque)
        XCTAssertEqual(ciOpaqueColor.red, 1.0)
        XCTAssertEqual(ciOpaqueColor.green, 1.0)
        XCTAssertEqual(ciOpaqueColor.blue, 1.0)
        XCTAssertEqual(ciOpaqueColor.alpha, 1.0)

        let ciSemiColor = CIColor(color: colorSemi)
        XCTAssertEqual(ciSemiColor.red, 1.0)
        XCTAssertEqual(ciSemiColor.green, 1.0)
        XCTAssertEqual(ciSemiColor.blue, 1.0)
        XCTAssertLessThan(abs(ciSemiColor.alpha - 0.5), 0.01)

        let ciTransparentColor = CIColor(color: colorTransparent)
        XCTAssertEqual(ciTransparentColor.red, 1.0)
        XCTAssertEqual(ciTransparentColor.green, 1.0)
        XCTAssertEqual(ciTransparentColor.blue, 1.0)
        XCTAssertEqual(ciTransparentColor.alpha, 0.0)
    }
}
