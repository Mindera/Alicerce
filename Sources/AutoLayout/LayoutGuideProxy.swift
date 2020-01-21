import UIKit

public final class LayoutGuideProxy: PositionConstrainableProxy {

    // MARK: - PositionConstrainable

    public var top: NSLayoutYAxisAnchor { guide.topAnchor }

    public var bottom: NSLayoutYAxisAnchor { guide.bottomAnchor }

    public var leading: NSLayoutXAxisAnchor { guide.leadingAnchor }

    public var trailing: NSLayoutXAxisAnchor { guide.trailingAnchor }

    public var left: NSLayoutXAxisAnchor { guide.leftAnchor }

    public var right: NSLayoutXAxisAnchor { guide.rightAnchor }

    public var height: NSLayoutDimension { guide.heightAnchor }

    public var width: NSLayoutDimension { guide.widthAnchor }

    public var centerY: NSLayoutYAxisAnchor { guide.centerYAnchor }

    public var centerX: NSLayoutXAxisAnchor { guide.centerXAnchor }

    // MARK: - ConstrainableProxy

    public let context: LayoutContext
    public var item: AnyObject { guide }

    private let guide: UILayoutGuide

    // MARK: - Lifecycle

    init(context: LayoutContext, guide: UILayoutGuide) {

        self.context = context
        self.guide = guide
    }

    public func prepare() {}
}
