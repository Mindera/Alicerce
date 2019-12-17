import UIKit

extension NSLayoutConstraint {

    func with(priority: UILayoutPriority) -> NSLayoutConstraint {

        self.priority = priority
        return self
    }

    func set(active: Bool) -> NSLayoutConstraint {

        isActive = active
        return self
    }
}
