import UIKit

extension UIEdgeInsets {

    @available(iOS 11.0, *)
    public var directional: NSDirectionalEdgeInsets { .init(top: top, leading: left, bottom: bottom, trailing: right) }
}
