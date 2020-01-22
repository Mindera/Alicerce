import UIKit

public extension Array where Element: LeadingConstrainableProxy {

    @discardableResult
    func alignLeading() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map { first.leading(to: $0) }
    }
}

public extension Array where Element: TrailingConstrainableProxy {

    @discardableResult
    func alignTrailing() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map { first.trailing(to: $0) }
    }
}

public extension Array where Element: TopConstrainableProxy {

    @discardableResult
    func alignTop() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map { first.top(to: $0) }
    }
}

public extension Array where Element: BottomConstrainableProxy {

    @discardableResult
    func alignBottom() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map { first.bottom(to: $0) }
    }
}

public extension Array where Element: PositionConstrainableProxy {

    @discardableResult
    func alignCenterX() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map { first.centerX(to: $0) }
    }

    @discardableResult
    func alignCenterY() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map { first.centerY(to: $0) }
    }
}

public extension Array where Element: WidthConstrainableProxy {

    @discardableResult
    func equalWidth() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map { first.width(to: $0) }
    }

    @discardableResult
    func equal(width: CGFloat) -> [NSLayoutConstraint] {

        map { $0.width(width, relation: .equal) }
    }
}

public extension Array where Element: HeightConstrainableProxy {

    @discardableResult
    func equalHeight() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map { first.height(to: $0) }
    }
}

public extension Array where Element: LeadingConstrainableProxy & TrailingConstrainableProxy {

    @discardableResult
    func distributeHorizontally(margin: CGFloat = 0.0) -> [NSLayoutConstraint] {

        guard isEmpty == false else { return [] }
        return zip(self, self[1...]).map { first, second in
            second.leadingToTrailing(of: first, offset: margin)
        }
    }
}

public extension Array where Element: TopConstrainableProxy & BottomConstrainableProxy {

    @discardableResult
    func distributeVertically(margin: CGFloat = 0.0) -> [NSLayoutConstraint] {

        guard isEmpty == false else { return [] }
        return zip(self, self[1...]).map { first, second in
            second.topToBottom(of: first, offset: margin)
        }
    }
}
