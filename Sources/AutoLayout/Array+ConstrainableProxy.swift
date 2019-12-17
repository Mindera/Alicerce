import UIKit

extension Array where Element: LeadingConstrainableProxy {

    @discardableResult
    func alignLeading() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map {
            $0.prepare()
            return first.leading(to: $0)
        }
    }
}

extension Array where Element: TrailingConstrainableProxy {

    @discardableResult
    func alignTrailing() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map {
            $0.prepare()
            return first.trailing(to: $0)
        }
    }
}

extension Array where Element: TopConstrainableProxy {

    @discardableResult
    func alignTop() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map {
            $0.prepare()
            return first.top(to: $0)
        }
    }
}

extension Array where Element: BottomConstrainableProxy {

    @discardableResult
    func alignBottom() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map {
            $0.prepare()
            return first.bottom(to: $0)
        }
    }
}

extension Array where Element: PositionConstrainableProxy {

    @discardableResult
    func alignCenterX() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map {
            $0.prepare()
            return first.centerX(to: $0)
        }
    }

    @discardableResult
    func alignCenterY() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map {
            $0.prepare()
            return first.centerY(to: $0)
        }
    }
}

extension Array where Element: WidthConstrainableProxy {

    @discardableResult
    func equalWidth() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map {
            $0.prepare()
            return first.width(to: $0)
        }
    }

    @discardableResult
    func equal(width: CGFloat) -> [NSLayoutConstraint] {

        guard isEmpty == false else { return [] }
        return map {
            $0.prepare()
            return $0.width(width, relation: .equal)
        }
    }
}

extension Array where Element: HeightConstrainableProxy {

    @discardableResult
    func equalHeight() -> [NSLayoutConstraint] {

        guard let first = first else { return [] }
        return self[1...].map {
            $0.prepare()
            return first.height(to: $0)
        }
    }
}

extension Array where Element: LeadingConstrainableProxy & TrailingConstrainableProxy {

    @discardableResult
    func distributeHorizontally(margin: CGFloat = 0.0) -> [NSLayoutConstraint] {

        last?.prepare()
        return zip(self, self[1...]).map { first, second in
            second.leadingToTrailing(of: first, offset: margin)
        }
    }
}

extension Array where Element: TopConstrainableProxy & BottomConstrainableProxy {

    @discardableResult
    func distributeVertically(margin: CGFloat = 0.0) -> [NSLayoutConstraint] {

        last?.prepare()
        return zip(self, self[1...]).map { first, second in
            second.topToBottom(of: first, offset: margin)
        }
    }
}
