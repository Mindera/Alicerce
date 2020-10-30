// swiftlint:disable function_parameter_count

import UIKit

public final class LayoutContext {

    fileprivate var constraints: [NSLayoutConstraint] = []

    func add(_ constraint: NSLayoutConstraint) {

        constraints.append(constraint)
    }
}

public class ConstraintGroup {

    public init() { }

    internal init(constraints: [NSLayoutConstraint] = []) {

        self.constraints = constraints
    }

    fileprivate var constraints: [NSLayoutConstraint] = [] {
        willSet {
            if isActive { deactivate() }
        }
        didSet {
            if isActive { activate() }
        }
    }

    public var isActive: Bool {
        get { constraints.allSatisfy { $0.isActive } }
        set { newValue ? activate() : deactivate() }
    }

    private func activate() {

        NSLayoutConstraint.activate(constraints)
    }

    private func deactivate() {

        NSLayoutConstraint.deactivate(constraints)
    }
}

public final class ConstraintGroupToggle<T: Hashable> {

    private var constraintGroups: [T: ConstraintGroup] = [:]

    public init(initial: T? = nil, constraintGroups: [T: ConstraintGroup]) {

        self.constraintGroups = constraintGroups

        if let initial = initial {
            activate(initial)
        } else {
            deactivate()
        }
    }

    public func activate(_ key: T) {

        constraintGroups.lazy.filter { $0 != key && $1.isActive }.forEach { $1.isActive = false }

        if let constraintGroup = constraintGroups[key] {
            constraintGroup.isActive = true
        }
    }

    public func deactivate() {

        constraintGroups.forEach { $1.isActive = false }
    }
}

@discardableResult
public func constrain<A: LayoutItem>(
    _ a: A,
    replacing group: ConstraintGroup = .init(),
    activate: Bool = true,
    constraints: (A.ProxyType) -> Void
) -> ConstraintGroup {

    let context = LayoutContext()

    let a = a.proxy(with: context)

    constraints(a)

    group.constraints = context.constraints
    group.isActive = activate

    return group
}

@discardableResult
public func constrain<A: LayoutItem, B: LayoutItem>(
    _ a: A,
    _ b: B,
    replacing group: ConstraintGroup = .init(),
    activate: Bool = true,
    constraints: (A.ProxyType, B.ProxyType) -> Void
) -> ConstraintGroup {

    let context = LayoutContext()

    let a = a.proxy(with: context)
    let b = b.proxy(with: context)

    constraints(a, b)

    group.constraints = context.constraints
    group.isActive = activate

    return group
}

@discardableResult
public func constrain<A: LayoutItem, B: LayoutItem, C: LayoutItem>(
    _ a: A,
    _ b: B,
    _ c: C,
    replacing group: ConstraintGroup = .init(),
    activate: Bool = true,
    constraints: (A.ProxyType, B.ProxyType, C.ProxyType) -> Void
) -> ConstraintGroup {

    let context = LayoutContext()

    let a = a.proxy(with: context)
    let b = b.proxy(with: context)
    let c = c.proxy(with: context)

    constraints(a, b, c)

    group.constraints = context.constraints
    group.isActive = activate

    return group
}

@discardableResult
public func constrain<A: LayoutItem, B: LayoutItem, C: LayoutItem, D: LayoutItem>(
    _ a: A,
    _ b: B,
    _ c: C,
    _ d: D,
    replacing group: ConstraintGroup = .init(),
    activate: Bool = true,
    constraints: (A.ProxyType, B.ProxyType, C.ProxyType, D.ProxyType) -> Void
) -> ConstraintGroup {

    let context = LayoutContext()

    let a = a.proxy(with: context)
    let b = b.proxy(with: context)
    let c = c.proxy(with: context)
    let d = d.proxy(with: context)

    constraints(a, b, c, d)

    group.constraints = context.constraints
    group.isActive = activate

    return group
}

@discardableResult
public func constrain<A: LayoutItem, B: LayoutItem, C: LayoutItem, D: LayoutItem, E: LayoutItem>(
    _ a: A,
    _ b: B,
    _ c: C,
    _ d: D,
    _ e: E,
    replacing group: ConstraintGroup = .init(),
    activate: Bool = true,
    constraints: (A.ProxyType, B.ProxyType, C.ProxyType, D.ProxyType, E.ProxyType) -> Void
) -> ConstraintGroup {

    let context = LayoutContext()

    let a = a.proxy(with: context)
    let b = b.proxy(with: context)
    let c = c.proxy(with: context)
    let d = d.proxy(with: context)
    let e = e.proxy(with: context)

    constraints(a, b, c, d, e)

    group.constraints = context.constraints
    group.isActive = activate

    return group
}

@discardableResult
public func constrain<A: LayoutItem, B: LayoutItem, C: LayoutItem, D: LayoutItem, E: LayoutItem, F: LayoutItem>(
    _ a: A,
    _ b: B,
    _ c: C,
    _ d: D,
    _ e: E,
    _ f: F,
    replacing group: ConstraintGroup = .init(),
    activate: Bool = true,
    constraints: (A.ProxyType, B.ProxyType, C.ProxyType, D.ProxyType, E.ProxyType, F.ProxyType) -> Void
) -> ConstraintGroup {

    let context = LayoutContext()

    let a = a.proxy(with: context)
    let b = b.proxy(with: context)
    let c = c.proxy(with: context)
    let d = d.proxy(with: context)
    let e = e.proxy(with: context)
    let f = f.proxy(with: context)

    constraints(a, b, c, d, e, f)

    group.constraints = context.constraints
    group.isActive = activate

    return group
}

@discardableResult
public func constrain<T: LayoutItem>(
    _ items: [T],
    replacing group: ConstraintGroup = .init(),
    activate: Bool = true,
    constraints: ([T.ProxyType]) -> Void
) -> ConstraintGroup {

    let context = LayoutContext()

    let proxies = items.map { $0.proxy(with: context) }

    constraints(proxies)

    group.constraints = context.constraints
    group.isActive = activate

    return group
}

@discardableResult
public func constrain(
    clearing group: ConstraintGroup = .init()
) -> ConstraintGroup {

    group.constraints = []

    return group
}
