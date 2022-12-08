import UIKit

extension NSDirectionalEdgeInsets {

    public var nonDirectional: UIEdgeInsets { .init(top: top, left: leading, bottom: bottom, right: trailing) }
}
