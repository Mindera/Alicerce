import UIKit

public final class ViewProxy: PositionConstrainableProxy, BaselineConstrainableProxy {

    // MARK: - PositionConstrainableProxy

    public var top: NSLayoutYAxisAnchor { view.topAnchor }

    public var bottom: NSLayoutYAxisAnchor { view.bottomAnchor }

    public var leading: NSLayoutXAxisAnchor { view.leadingAnchor }

    public var trailing: NSLayoutXAxisAnchor { view.trailingAnchor }

    public var left: NSLayoutXAxisAnchor { view.leftAnchor }

    public var right: NSLayoutXAxisAnchor { view.rightAnchor }

    public var height: NSLayoutDimension { view.heightAnchor }

    public var width: NSLayoutDimension { view.widthAnchor }

    public var centerY: NSLayoutYAxisAnchor { view.centerYAnchor }

    public var centerX: NSLayoutXAxisAnchor { view.centerXAnchor }

    // MARK: - BaselineConstrainableProxy

    public var firstBaseline: NSLayoutYAxisAnchor { view.firstBaselineAnchor }

    public var lastBaseline: NSLayoutYAxisAnchor { view.lastBaselineAnchor }

    // MARK: - ConstrainableProxy

    public let context: LayoutContext
    public var item: AnyObject { view }

    // MARK: - Properties

    public var layoutMarginsGuide: LayoutGuideProxy { view.layoutMarginsGuide.proxy(with: context) }

    public var safeAreaLayoutGuide: LayoutGuideProxy { view.safeAreaLayoutGuide.proxy(with: context) }

    private let view: UIView

    // MARK: - Lifecycle

    init(context: LayoutContext, view: UIView) {

        self.context = context
        self.view = view
    }

    public func prepare() {

        view.translatesAutoresizingMaskIntoConstraints = false
    }
}
