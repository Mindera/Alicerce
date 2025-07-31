import UIKit

public extension UIColor {
    convenience init(hexValue: String) throws {
        let hex = hexValue
            .filter { $0.isLetter || $0.isNumber }
            .prepending("ff")
            .suffix(8)
            .asString

        guard hex.count == 8 else {
            throw ColorError.invalidHexSize(hexValue)
        }

        var hexInt: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&hexInt) else {
            throw ColorError.invalidHexValue(hexValue)
        }

        let components = UIColor.components(hex: hexInt)

        self.init(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }

    convenience init(hex: String) {
        do {
            try self.init(hexValue: hex)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    var hexString: String {
        String(format:"#%06x", (asHexIntWithAlpha & 0x00FFFFFF))
    }

    var hexStringWithAlpha: String {
        String(format:"#%08x", asHexIntWithAlpha)
    }
}

private extension UIColor {
    typealias Components = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)

    enum ColorError: LocalizedError {
        case invalidHexValue(String)
        case invalidHexSize(String)

        var localizedDescription: String {
            switch self {
            case let .invalidHexValue(hex): "😱 Cannot convert `#\(hex)` into `UInt64`"
            case let .invalidHexSize(hex): "😱 Hex size of `#\(hex)` not supported 😇"
            }
        }
    }

    static let divisor = CGFloat(255)

    static func components(hex: UInt64) -> Components {

        let alpha = CGFloat((hex & 0xFF000000) >> 24) / UIColor.divisor
        let red = CGFloat((hex & 0x00FF0000) >> 16) / UIColor.divisor
        let green = CGFloat((hex & 0x0000FF00) >> 8) / UIColor.divisor
        let blue = CGFloat(hex & 0x000000FF) / UIColor.divisor

        return (red, green, blue, alpha)
    }

    var asHexIntWithAlpha: Int {

        var components = UIColor.components(hex: 0)
        getRed(&components.red, green: &components.green, blue: &components.blue, alpha: &components.alpha)

        let a = Int(components.alpha * UIColor.divisor)
        let r = Int(components.red * UIColor.divisor)
        let g = Int(components.green * UIColor.divisor)
        let b = Int(components.blue * UIColor.divisor)
        let argb: Int = a << 24 | r << 16 | g << 8 | b << 0

        return argb
    }
}

private extension String.SubSequence {
    var asString: String {
        String(self)
    }
}
