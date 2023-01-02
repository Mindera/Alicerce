import UIKit

public extension UIColor {
    private static let divisor = CGFloat(255)

    private typealias Components = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)

    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var hexValue: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&hexValue) else {
            fatalError("😱 Cannot convert string into `UInt64`")
        }

        let components: Components = {
            switch hex.count {
            case 6: return UIColor.components(fromHex6: hexValue)
            case 8: return UIColor.components(fromHex8: hexValue)
            default: fatalError("😱 hex size not supported 😇")
            }
        }()

        self.init(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }

    var hexString: String {

        var components = UIColor.components(fromHex6: 0)
        getRed(&components.red, green: &components.green, blue: &components.blue, alpha: &components.alpha)

        let r = Int(components.red * UIColor.divisor)
        let g = Int(components.green * UIColor.divisor)
        let b = Int(components.blue * UIColor.divisor)
        let rgb: Int = r << 16 | g << 8 | b << 0

        return String(format:"#%06x", rgb)
    }

    var hexStringWithAlpha: String {

        var components = UIColor.components(fromHex8: 0)
        getRed(&components.red, green: &components.green, blue: &components.blue, alpha: &components.alpha)

        let a = Int(components.alpha * UIColor.divisor)
        let r = Int(components.red * UIColor.divisor)
        let g = Int(components.green * UIColor.divisor)
        let b = Int(components.blue * UIColor.divisor)
        let argb: Int = a << 24 | r << 16 | g << 8 | b << 0

        return String(format:"#%08x", argb)
    }

    // MARK: - Private Methods

    private static func components(fromHex6 hex: UInt64) -> Components {
        let red = CGFloat((hex & 0xFF0000) >> 16) / UIColor.divisor
        let green = CGFloat((hex & 0x00FF00) >> 8) / UIColor.divisor
        let blue = CGFloat(hex & 0x0000FF) / UIColor.divisor

        return (red, green, blue, 1.0)
    }

    private static func components(fromHex8 hex: UInt64) -> Components {

        let alpha = CGFloat((hex & 0xFF000000) >> 24) / UIColor.divisor
        let red = CGFloat((hex & 0x00FF0000) >> 16) / UIColor.divisor
        let green = CGFloat((hex & 0x0000FF00) >> 8) / UIColor.divisor
        let blue = CGFloat(hex & 0x000000FF) / UIColor.divisor

        return (red, green, blue, alpha)
    }
}
