import UIKit

public protocol LayoutItem: AnyObject {

    associatedtype ProxyType: ConstrainableProxy

    func proxy(with context: LayoutContext) -> ProxyType
}

// MARK: - UIView

extension UIView: LayoutItem {

    public typealias ProxyType = ViewProxy

    public func proxy(with context: LayoutContext) -> ViewProxy {

        ViewProxy(context: context, view: self)
    }
}

// MARK: - UILayoutGuide

extension UILayoutGuide: LayoutItem {

    public typealias ProxyType = LayoutGuideProxy

    public func proxy(with context: LayoutContext) -> LayoutGuideProxy {

        LayoutGuideProxy(context: context, guide: self)
    }
}
