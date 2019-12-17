import UIKit

final class LayoutGuideProxy: PositionConstrainableProxy {

    // MARK: - PositionConstrainable

    var top: NSLayoutYAxisAnchor {
        return guide.topAnchor
    }

    var bottom: NSLayoutYAxisAnchor {
        return guide.bottomAnchor
    }

    var leading: NSLayoutXAxisAnchor {
        return guide.leadingAnchor
    }

    var trailing: NSLayoutXAxisAnchor {
        return guide.trailingAnchor
    }

    var left: NSLayoutXAxisAnchor {
        return guide.leftAnchor
    }

    var right: NSLayoutXAxisAnchor {
        return guide.rightAnchor
    }

    var height: NSLayoutDimension {
        return guide.heightAnchor
    }

    var width: NSLayoutDimension {
        return guide.widthAnchor
    }

    var centerY: NSLayoutYAxisAnchor {
        return guide.centerYAnchor
    }

    var centerX: NSLayoutXAxisAnchor {
        return guide.centerXAnchor
    }

    // MARK: - ConstrainableProxy

    let context: LayoutContext
    var item: AnyObject { return guide }

    private let guide: UILayoutGuide

    // MARK: - Lifecycle

    init(context: LayoutContext, guide: UILayoutGuide) {

        self.context = context
        self.guide = guide
    }

    func prepare() {}
}
