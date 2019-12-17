import UIKit

protocol LayoutItem: AnyObject {

    associatedtype ProxyType: ConstrainableProxy

    func proxy(with context: LayoutContext) -> ProxyType
}

// MARK: - UIView

extension UIView: LayoutItem {

    typealias ProxyType = ViewProxy

    func proxy(with context: LayoutContext) -> ViewProxy {

        return ViewProxy(context: context, view: self)
    }
}

// MARK: - UILayoutGuide

extension UILayoutGuide: LayoutItem {

    typealias ProxyType = LayoutGuideProxy

    func proxy(with context: LayoutContext) -> LayoutGuideProxy {

        return LayoutGuideProxy(context: context, guide: self)
    }
}
