import UIKit

extension NSLayoutConstraint {

    convenience init(
        item item1: Any,
        attribute attribute1: NSLayoutConstraint.Attribute,
        relatedBy relation: NSLayoutConstraint.Relation,
        toItem item2: Any?,
        attribute attribute2: NSLayoutConstraint.Attribute,
        multiplier: CGFloat,
        constant: CGFloat,
        priority: UILayoutPriority,
        active: Bool
    ) {

        self.init(
            item: item1,
            attribute: attribute1,
            relatedBy: relation,
            toItem: item2,
            attribute: attribute2,
            multiplier: multiplier,
            constant: constant
        )

        self.priority = priority
        isActive = active
    }
}
