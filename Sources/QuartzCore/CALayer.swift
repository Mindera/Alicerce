import QuartzCore

extension CALayer {

    static func solidLayer(color: UIColor) -> CALayer {
        return {
            $0.backgroundColor = color.cgColor
            return $0
        }(CALayer())
    }
}
