import UIKit

final class LayoutGuideProxy: PositionConstrainableProxy {

    // MARK: - PositionConstrainable

    var top: NSLayoutYAxisAnchor { guide.topAnchor }

    var bottom: NSLayoutYAxisAnchor { guide.bottomAnchor }

    var leading: NSLayoutXAxisAnchor { guide.leadingAnchor }

    var trailing: NSLayoutXAxisAnchor { guide.trailingAnchor }

    var left: NSLayoutXAxisAnchor { guide.leftAnchor }

    var right: NSLayoutXAxisAnchor { guide.rightAnchor }

    var height: NSLayoutDimension { guide.heightAnchor }

    var width: NSLayoutDimension { guide.widthAnchor }

    var centerY: NSLayoutYAxisAnchor { guide.centerYAnchor }

    var centerX: NSLayoutXAxisAnchor { guide.centerXAnchor }

    // MARK: - ConstrainableProxy

    let context: LayoutContext
    var item: AnyObject { guide }

    private let guide: UILayoutGuide

    // MARK: - Lifecycle

    init(context: LayoutContext, guide: UILayoutGuide) {

        self.context = context
        self.guide = guide
    }

    func prepare() {}
}
