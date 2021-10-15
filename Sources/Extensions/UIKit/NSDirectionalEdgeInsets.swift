import UIKit

@available(iOS 11.0, *)
extension NSDirectionalEdgeInsets {

    public var nonDirectional: UIEdgeInsets { .init(top: top, left: leading, bottom: bottom, right: trailing) }
}
