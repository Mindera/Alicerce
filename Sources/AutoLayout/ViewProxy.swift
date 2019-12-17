import UIKit

final class ViewProxy: PositionConstrainableProxy, BaselineConstrainableProxy {

    // MARK: - PositionConstrainableProxy

    var top: NSLayoutYAxisAnchor {
        return view.topAnchor
    }

    var bottom: NSLayoutYAxisAnchor {
        return view.bottomAnchor
    }

    var leading: NSLayoutXAxisAnchor {
        return view.leadingAnchor
    }

    var trailing: NSLayoutXAxisAnchor {
        return view.trailingAnchor
    }

    var left: NSLayoutXAxisAnchor {
        return view.leftAnchor
    }

    var right: NSLayoutXAxisAnchor {
        return view.rightAnchor
    }

    var height: NSLayoutDimension {
        return view.heightAnchor
    }

    var width: NSLayoutDimension {
        return view.widthAnchor
    }

    var centerY: NSLayoutYAxisAnchor {
        return view.centerYAnchor
    }

    var centerX: NSLayoutXAxisAnchor {
        return view.centerXAnchor
    }

    // MARK: - BaselineConstrainableProxy

    var firstBaseline: NSLayoutYAxisAnchor {
        return view.firstBaselineAnchor
    }

    var lastBaseline: NSLayoutYAxisAnchor {
        return view.lastBaselineAnchor
    }

    // MARK: - ConstrainableProxy

    let context: LayoutContext
    var item: AnyObject { return view }

    // MARK: - Properties

    var layoutMarginsGuide: LayoutGuideProxy {
        return view.layoutMarginsGuide.proxy(with: context)
    }

    @available(iOS 11.0, *)
    var safeAreaLayoutGuide: LayoutGuideProxy {
        return view.safeAreaLayoutGuide.proxy(with: context)
    }

    var safeArea: LayoutGuideProxy {

        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide
        } else {
            return layoutMarginsGuide
        }
    }

    private let view: UIView

    // MARK: - Lifecycle

    init(context: LayoutContext, view: UIView) {

        self.context = context
        self.view = view
    }

    func prepare() {

        return view.translatesAutoresizingMaskIntoConstraints = false
    }
}
