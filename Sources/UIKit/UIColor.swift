//
//  UIColor.swift
//  Alicerce
//
//  Created by Luís Portela on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public extension UIColor {
    private static let divisor = CGFloat(255)

    private typealias Components = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)

    public convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var hexValue: UInt32 = 0

        guard Scanner(string: hex).scanHexInt32(&hexValue) else {
            fatalError("😱 Cannot convert string into `UInt32`")
        }

        let components: Components = {
            switch hex.characters.count {
            case 6:
                return UIColor.components(fromHex6: hexValue)
            case 8:
                return UIColor.components(fromHex8: hexValue)
            default:
                fatalError("😱 hex size not supported 😇")
            }
        }()

        self.init(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }

    var hexString: String {

        var components = UIColor.components(fromHex6: 0)
        getRed(&components.red, green: &components.green, blue: &components.blue, alpha: &components.alpha)
        let rgb: Int = (Int)(components.red * UIColor.divisor) << 16
            | (Int)(components.green * UIColor.divisor) << 8
            | (Int)(components.blue * UIColor.divisor) << 0
        return String(format:"#%06x", rgb)
    }

    var hexStringWithAlpha: String {

        var components = UIColor.components(fromHex8: 0)
        getRed(&components.red, green: &components.green, blue: &components.blue, alpha: &components.alpha)
        let argb: Int = (Int)(components.alpha * UIColor.divisor) << 24
            | (Int)(components.red * UIColor.divisor) << 16
            | (Int)(components.green * UIColor.divisor) << 8
            | (Int)(components.blue * UIColor.divisor) << 0
        return String(format:"#%08x", argb)
    }

    // MARK: - Private Methods

    private static func components(fromHex6 hex: UInt32) -> Components {
        let red = CGFloat((hex & 0xFF0000) >> 16) / UIColor.divisor
        let green = CGFloat((hex & 0x00FF00) >> 8) / UIColor.divisor
        let blue = CGFloat(hex & 0x0000FF) / UIColor.divisor

        return (red, green, blue, 1.0)
    }

    private static func components(fromHex8 hex: UInt32) -> Components {

        let alpha = CGFloat((hex & 0xFF000000) >> 24) / UIColor.divisor
        let red = CGFloat((hex & 0x00FF0000) >> 16) / UIColor.divisor
        let green = CGFloat((hex & 0x0000FF00) >> 8) / UIColor.divisor
        let blue = CGFloat(hex & 0x000000FF) / UIColor.divisor
        
        return (red, green, blue, alpha)
    }
}
