import UIKit

public protocol NibView {
    static var nib: UINib { get }
}

public extension NibView where Self: UIView {

    /// Return an `UINib` for the given view, assuming the .xib file will have the same name as the view.
    /// - attention: Generic classes are **not** supported, since they can't be specialized by IB at runtime
    static var nib: UINib {
        assert(!"\(self)".contains("<"), "😢 Generic views are not currently supported, since IB can't specialize!")

        return UINib(nibName: "\(self)", bundle: Bundle(for: self))
    }
}
