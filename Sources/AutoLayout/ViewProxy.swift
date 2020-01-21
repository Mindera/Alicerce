import UIKit

final class ViewProxy: PositionConstrainableProxy, BaselineConstrainableProxy {

    // MARK: - PositionConstrainableProxy

    var top: NSLayoutYAxisAnchor { view.topAnchor }

    var bottom: NSLayoutYAxisAnchor { view.bottomAnchor }

    var leading: NSLayoutXAxisAnchor { view.leadingAnchor }

    var trailing: NSLayoutXAxisAnchor { view.trailingAnchor }

    var left: NSLayoutXAxisAnchor { view.leftAnchor }

    var right: NSLayoutXAxisAnchor { view.rightAnchor }

    var height: NSLayoutDimension { view.heightAnchor }

    var width: NSLayoutDimension { view.widthAnchor }

    var centerY: NSLayoutYAxisAnchor { view.centerYAnchor }

    var centerX: NSLayoutXAxisAnchor { view.centerXAnchor }

    // MARK: - BaselineConstrainableProxy

    var firstBaseline: NSLayoutYAxisAnchor { view.firstBaselineAnchor }

    var lastBaseline: NSLayoutYAxisAnchor { view.lastBaselineAnchor }

    // MARK: - ConstrainableProxy

    let context: LayoutContext
    var item: AnyObject { view }

    // MARK: - Properties

    var layoutMarginsGuide: LayoutGuideProxy { view.layoutMarginsGuide.proxy(with: context) }

    @available(iOS 11.0, *)
    var safeAreaLayoutGuide: LayoutGuideProxy { view.safeAreaLayoutGuide.proxy(with: context) }

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

        view.translatesAutoresizingMaskIntoConstraints = false
    }
}
