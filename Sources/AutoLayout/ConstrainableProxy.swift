// swiftlint:disable file_length function_parameter_count

#if canImport(AlicerceExtensions)
import AlicerceExtensions
#endif
import UIKit

public protocol ConstrainableProxy: AnyObject {

    var context: LayoutContext { get }
    var item: AnyObject { get }

    func prepare()
}

public protocol TopConstrainableProxy: ConstrainableProxy {

    var top: NSLayoutYAxisAnchor { get }
}

public extension TopConstrainableProxy {

    @discardableResult
    func top(
        to anotherProxy: TopConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: top,
            to: anotherProxy.top,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func topToBottom(
        of anotherProxy: BottomConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: top,
            to: anotherProxy.bottom,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func topToFirstBaseline(
        of anotherProxy: BaselineConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: top,
            to: anotherProxy.firstBaseline,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func topToLastBaseline(
        of anotherProxy: BaselineConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: top,
            to: anotherProxy.lastBaseline,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func topToCenterY(
        of anotherProxy: CenterYConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: top,
            to: anotherProxy.centerY,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol BottomConstrainableProxy: ConstrainableProxy {

    var bottom: NSLayoutYAxisAnchor { get }
}

public extension BottomConstrainableProxy {

    @discardableResult
    func bottom(
        to anotherProxy: BottomConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: bottom,
            to: anotherProxy.bottom,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func bottomToTop(
        of anotherProxy: TopConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: bottom,
            to: anotherProxy.top,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func bottomToFirstBaseline(
        of anotherProxy: BaselineConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: bottom,
            to: anotherProxy.firstBaseline,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func bottomToLastBaseline(
        of anotherProxy: BaselineConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: bottom,
            to: anotherProxy.lastBaseline,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func bottomToCenterY(
        of anotherProxy: CenterYConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: bottom,
            to: anotherProxy.centerY,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol LeadingConstrainableProxy: ConstrainableProxy {

    var leading: NSLayoutXAxisAnchor { get }
}

public extension LeadingConstrainableProxy {

    @discardableResult
    func leading(
        to anotherProxy: LeadingConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: leading,
            to: anotherProxy.leading,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func leadingToTrailing(
        of anotherProxy: TrailingConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: leading,
            to: anotherProxy.trailing,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func leadingToCenterX(
        of anotherProxy: CenterXConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: leading,
            to: anotherProxy.centerX,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol LeftConstrainableProxy: ConstrainableProxy {

    var left: NSLayoutXAxisAnchor { get }
}

public extension LeftConstrainableProxy {

    @discardableResult
    func left(
        to anotherProxy: LeftConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: left,
            to: anotherProxy.left,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func leftToRight(
        of anotherProxy: RightConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: left,
            to: anotherProxy.right,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func leftToCenterX(
        of anotherProxy: CenterXConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: left,
            to: anotherProxy.centerX,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol RightConstrainableProxy: ConstrainableProxy {

    var right: NSLayoutXAxisAnchor { get }
}

public extension RightConstrainableProxy {

    @discardableResult
    func right(
        to anotherProxy: RightConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: right,
            to: anotherProxy.right,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func rightToLeft(
        of anotherProxy: LeftConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: right,
            to: anotherProxy.left,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func rightToCenterX(
        of anotherProxy: CenterXConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: right,
            to: anotherProxy.centerX,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol TrailingConstrainableProxy: ConstrainableProxy {

    var trailing: NSLayoutXAxisAnchor { get }
}

public extension TrailingConstrainableProxy {

    @discardableResult
    func trailing(
        to anotherProxy: TrailingConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: trailing,
            to: anotherProxy.trailing,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func trailingToLeading(
        of anotherProxy: LeadingConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: trailing,
            to: anotherProxy.leading,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func trailingToCenterX(
        of anotherProxy: CenterXConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: trailing,
            to: anotherProxy.centerX,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol EdgesConstrainableProxy: TopConstrainableProxy,
    BottomConstrainableProxy,
    LeadingConstrainableProxy,
    TrailingConstrainableProxy,
    LeftConstrainableProxy,
    RightConstrainableProxy {}

public extension EdgesConstrainableProxy {

    @discardableResult
    func edges(
        to anotherProxy: EdgesConstrainableProxy,
        insets: UIEdgeInsets = .zero,
        topRelation: ConstraintRelation = .equal,
        topPriority: UILayoutPriority = .required,
        leadingRelation: ConstraintRelation = .equal,
        leadingPriority: UILayoutPriority = .required,
        bottomRelation: ConstraintRelation = .equal,
        bottomPriority: UILayoutPriority = .required,
        trailingRelation: ConstraintRelation = .equal,
        trailingPriority: UILayoutPriority = .required
    ) -> [NSLayoutConstraint] {

        [
            top(to: anotherProxy, offset: insets.top, relation: topRelation, priority:topPriority),
            leading(to: anotherProxy, offset: insets.left, relation: leadingRelation, priority: leadingPriority),
            bottom(to: anotherProxy, offset: -insets.bottom, relation: bottomRelation, priority: bottomPriority),
            trailing(to: anotherProxy, offset: -insets.right, relation: trailingRelation, priority: trailingPriority)
        ]
    }

    @_disfavoredOverload
    @discardableResult
    func edges(
        to anotherProxy: EdgesConstrainableProxy,
        directionalInsets insets: NSDirectionalEdgeInsets = .zero,
        topRelation: ConstraintRelation = .equal,
        topPriority: UILayoutPriority = .required,
        leadingRelation: ConstraintRelation = .equal,
        leadingPriority: UILayoutPriority = .required,
        bottomRelation: ConstraintRelation = .equal,
        bottomPriority: UILayoutPriority = .required,
        trailingRelation: ConstraintRelation = .equal,
        trailingPriority: UILayoutPriority = .required
    ) -> [NSLayoutConstraint] {

        edges(
            to: anotherProxy,
            insets: insets.nonDirectional,
            topRelation: topRelation,
            topPriority: topPriority,
            leadingRelation: leadingRelation,
            leadingPriority: leadingPriority,
            bottomRelation: bottomRelation,
            bottomPriority: bottomPriority,
            trailingRelation: trailingRelation,
            trailingPriority: trailingPriority
        )
    }
}

public protocol CenterYConstrainableProxy: ConstrainableProxy {

    var centerY: NSLayoutYAxisAnchor { get }
}

public extension CenterYConstrainableProxy {

    @discardableResult
    func centerY(
        to view: PositionConstrainableProxy,
        multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        center(
            axis: .vertical,
            to: view,
            multiplier: multiplier,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func centerYToTop(
        of view: PositionConstrainableProxy,
        multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        center(
            axis: .vertical,
            to: view,
            toAttribute: .top,
            multiplier: multiplier,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func centerYToBottom(
        of view: PositionConstrainableProxy,
        multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        center(
            axis: .vertical,
            to: view,
            toAttribute: .bottom,
            multiplier: multiplier,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func centerYToFirstBaseline(
        of anotherProxy: BaselineConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: centerY,
            to: anotherProxy.firstBaseline,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func centerYToLastBaseline(
        of anotherProxy: BaselineConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: centerY,
            to: anotherProxy.lastBaseline,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol CenterXConstrainableProxy: ConstrainableProxy {

    var centerX: NSLayoutXAxisAnchor { get }
}

public extension CenterXConstrainableProxy {

    @discardableResult
    func centerX(
        to view: PositionConstrainableProxy,
        multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        center(
            axis: .horizontal,
            to: view,
            multiplier: multiplier,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func centerXToLeading(
        of anotherProxy: LeadingConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: centerX,
            to: anotherProxy.leading,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func centerXToTrailing(
        of anotherProxy: TrailingConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: centerX,
            to: anotherProxy.trailing,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol CenterConstrainableProxy: CenterXConstrainableProxy, CenterYConstrainableProxy {}

public extension CenterConstrainableProxy {

    @discardableResult
    func center(
        in view: PositionConstrainableProxy,
        offset: CGPoint = .zero,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> [NSLayoutConstraint] {

        let constraints: [NSLayoutConstraint] = [
            centerX(to: view, offset: offset.x, relation: relation, priority: priority),
            centerY(to: view, offset: offset.y, relation: relation, priority: priority)
        ]

        return constraints
    }
}

public protocol WidthConstrainableProxy: ConstrainableProxy {

    var width: NSLayoutDimension { get }
}

public extension WidthConstrainableProxy {

    @discardableResult
    func width(
        _ width: CGFloat,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            dimension: self.width,
            constant: width,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func width(
        to view: WidthConstrainableProxy,
        multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: width,
            to: view.width,
            multiplier: multiplier,
            constant: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol HeightConstrainableProxy: ConstrainableProxy {

    var height: NSLayoutDimension { get }
}

public extension HeightConstrainableProxy {

    @discardableResult
    func height(
        _ height: CGFloat,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            dimension: self.height,
            constant: height,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func height(
        to view: HeightConstrainableProxy,
        multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: height,
            to: view.height,
            multiplier: multiplier,
            constant: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol SizeConstrainableProxy: WidthConstrainableProxy, HeightConstrainableProxy {}

public extension SizeConstrainableProxy {

    @discardableResult
    func size(
        _ size: CGSize,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> [NSLayoutConstraint] {

        let constraints: [NSLayoutConstraint] = [
            width(size.width, relation: relation, priority: priority),
            height(size.height, relation: relation, priority: priority)
        ]

        return constraints
    }

    @discardableResult
    func size(
        to view: SizeConstrainableProxy,
        multiplier: CGFloat = 1,
        insets: CGSize = .zero,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> [NSLayoutConstraint] {

        let constraints: [NSLayoutConstraint] = [
            width(to: view, multiplier: multiplier, offset: insets.width, relation: relation, priority: priority),
            height(to: view, multiplier: multiplier, offset: insets.height, relation: relation, priority: priority)
        ]

        return constraints
    }

    @discardableResult
    func aspectRatio(
        _ multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: width,
            to: height,
            multiplier: multiplier,
            constant: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol BaselineConstrainableProxy: ConstrainableProxy {

    var firstBaseline: NSLayoutYAxisAnchor { get }
    var lastBaseline: NSLayoutYAxisAnchor { get }
}

public extension BaselineConstrainableProxy {

    @discardableResult
    func firstBaseline(
        to view: BaselineConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: firstBaseline,
            to: view.firstBaseline,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func firstBaselineToTop(
        of view: TopConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: firstBaseline,
            to: view.top,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func firstBaselineToBottom(
        of view: BottomConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: firstBaseline,
            to: view.bottom,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func firstBaselineToCenterY(
        of view: CenterYConstrainableProxy,
        multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: firstBaseline,
            to: view.centerY,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func lastBaseline(
        to view: BaselineConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: lastBaseline,
            to: view.lastBaseline,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func lastBaselineToTop(
        of view: TopConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: lastBaseline,
            to: view.top,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func lastBaselineToBottom(
        of view: BottomConstrainableProxy,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: lastBaseline,
            to: view.bottom,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }

    @discardableResult
    func lastBaselineToCenterY(
        of view: CenterYConstrainableProxy,
        multiplier: CGFloat = 1,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        constrain(
            from: lastBaseline,
            to: view.centerY,
            offset: offset,
            relation: relation,
            priority: priority
        )
    }
}

public protocol PositionConstrainableProxy: EdgesConstrainableProxy, SizeConstrainableProxy, CenterConstrainableProxy {}

// MARK: - Helpers

private extension ConstrainableProxy {

    // MARK: - NSLayoutYAxisAnchor

    func constrain(
        from: NSLayoutYAxisAnchor,
        to: NSLayoutYAxisAnchor,
        offset: CGFloat,
        relation: ConstraintRelation,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {

        let constraint: NSLayoutConstraint
        switch relation {
        case .equal:
            constraint = from.constraint(equalTo: to, constant: offset)
        case .equalOrLess:
            constraint = from.constraint(lessThanOrEqualTo: to, constant: offset)
        case .equalOrGreater:
            constraint = from.constraint(greaterThanOrEqualTo: to, constant: offset)
        }

        let result = constraint.with(priority: priority)

        prepare()
        context.add(result)

        return result
    }

    // MARK: - NSLayoutXAxisAnchor

    func constrain(
        from: NSLayoutXAxisAnchor,
        to: NSLayoutXAxisAnchor,
        offset: CGFloat = 0,
        relation: ConstraintRelation = .equal,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {

        let constraint: NSLayoutConstraint
        switch relation {
        case .equal:
            constraint = from.constraint(equalTo: to, constant: offset)
        case .equalOrLess:
            constraint = from.constraint(lessThanOrEqualTo: to, constant: offset)
        case .equalOrGreater:
            constraint = from.constraint(greaterThanOrEqualTo: to, constant: offset)
        }

        let result = constraint.with(priority: priority)

        prepare()
        context.add(result)

        return result
    }

    // MARK: - NSLayoutDimension

    func constrain(
        from: NSLayoutDimension,
        to: NSLayoutDimension,
        multiplier: CGFloat,
        constant: CGFloat,
        relation: ConstraintRelation,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {

        let constraint: NSLayoutConstraint
        switch relation {
        case .equal:
            constraint = from.constraint(equalTo: to, multiplier: multiplier, constant: constant)
        case .equalOrLess:
            constraint = from.constraint(lessThanOrEqualTo: to, multiplier: multiplier, constant: constant)
        case .equalOrGreater:
            constraint = from.constraint(greaterThanOrEqualTo: to, multiplier: multiplier, constant: constant)
        }

        let result = constraint.with(priority: priority)

        prepare()
        context.add(result)

        return result
    }

    func constrain(
        dimension: NSLayoutDimension,
        constant: CGFloat,
        relation: ConstraintRelation,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {

        let constraint: NSLayoutConstraint
        switch relation {
        case .equal:
            constraint = dimension.constraint(equalToConstant: constant)
        case .equalOrLess:
            constraint = dimension.constraint(lessThanOrEqualToConstant: constant)
        case .equalOrGreater:
            constraint = dimension.constraint(greaterThanOrEqualToConstant: constant)
        }

        let result = constraint.with(priority: priority)

        prepare()
        context.add(result)

        return result
    }

    func center(
        axis: NSLayoutConstraint.Axis,
        to: PositionConstrainableProxy,
        toAttribute: NSLayoutConstraint.Attribute? = nil,
        multiplier: CGFloat,
        offset: CGFloat,
        relation: ConstraintRelation,
        priority: UILayoutPriority
    ) -> NSLayoutConstraint {

        let attribute: NSLayoutConstraint.Attribute
        switch axis {
        case .horizontal:
            attribute = .centerX
        case .vertical:
            attribute = .centerY
        @unknown default:
            assertionFailure("🔥 Unexpected axis \(axis) to be centered! Assuming horizontal")
            attribute = .centerX
        }

        let _relation: NSLayoutConstraint.Relation
        switch relation {
        case .equal:
            _relation = .equal
        case .equalOrLess:
            _relation = .lessThanOrEqual
        case .equalOrGreater:
            _relation = .greaterThanOrEqual
        }

        let constraint = NSLayoutConstraint(
            item: item,
            attribute: attribute,
            relatedBy: _relation,
            toItem: to.item,
            attribute: toAttribute ?? attribute,
            multiplier: multiplier,
            constant: offset
        ).with(priority: priority)

        prepare()
        context.add(constraint)

        return constraint
    }
}
