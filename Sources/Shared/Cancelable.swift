import Foundation

/// A type that can be cancelled.
public protocol Cancelable: AnyObject {

    /// A flag indicating if this cancelable has already been cancelled.
    var isCancelled: Bool { get }

    /// Cancels the cancelable. If `self` has already been cancelled, it does nothing.
    func cancel()
}

// MARK: - Extensions

extension URLSessionTask: Cancelable {

    public var isCancelled: Bool { return state == .canceling }
}

extension DispatchWorkItem: Cancelable {}

// MARK: - Wrapper Cancelables

/// A cancelable that wraps another cancelable as a weak reference.
public final class WeakCancelable: Cancelable {

    /// The wrapped (weak) cancelable.
    private weak var cancelable: Cancelable?

    /// A flag indicating if the wrapped cancelable has already been cancelled (`true` if the wrapped instance was
    /// already deinit'ed).
    public var isCancelled: Bool {
        return cancelable?.isCancelled ?? true
    }

    /// Creates a new cancelable wrapping another one as a weak reference.
    ///
    /// - Parameter cancelable: The wrapped cancelable.
    public init(_ cancelable: Cancelable) {
        self.cancelable = cancelable
    }

    /// Cancels the cancelable.
    public func cancel() {
        guard let cancelable = cancelable, cancelable.isCancelled == false else { return }
        cancelable.cancel()
    }
}

/// A cancelable that wraps multiple cancelables.
public final class CancelableBag: Cancelable {

    /// The wrapped cancelables.
    private var cancelables: Atomic<[Cancelable]?>

    /// An atomic flag indicating if the cancelable has been cancelled (i.e. all wrapped cancelables).
    private var _isCancelled: Atomic<Bool>

    /// A flag indicating if the cancelable has been cancelled (i.e. all wrapped cancelables).
    public var isCancelled: Bool { return _isCancelled.value }

    /// Creates an instance of a cancelable bag.
    ///
    /// - Parameters:
    ///   - cancelables: The cancelables to initialize the bag with.
    public init<S: Sequence>(_ cancelables: S) where S.Iterator.Element == Cancelable {
        self.cancelables = Atomic(Array(cancelables))
        self._isCancelled = Atomic(false)
    }

    /// Creates an instance of a cancelable bag with no initial cancelables.
    public convenience init() {
        self.init([])
    }

    /// Adds a cancelable to the bag, if it hasn't been cancelled yet. If it has, the cancelable that is passed in
    /// **will be cancelled immediately** to ensure correctness and avoid lingering work that can't be cancelled.
    ///
    /// - Parameters:
    ///   - cancelable: The cancelable to add.
    public func add(cancelable: Cancelable) {
        guard isCancelled == false else {
            cancelable.cancel()
            return
        }

        cancelables.modify { $0?.append(cancelable) }
    }

    /// Cancels all the cancelables contained in the bag, if it hasn't been cancelled yet.
    public func cancel() {
        let shouldCancel: Bool = _isCancelled.modify {
            guard $0 == false else { return false }
            $0 = true
            return true
        }

        guard shouldCancel else { return }

        cancelables.swap(nil)?.forEach { $0.cancel() }
    }
}

/// A placeholder cancelable that doesn't cancel anything.
public final class DummyCancelable: Cancelable {

    /// A flag indicating if the cancelable has been cancelled.
    public var isCancelled: Bool { return false }

    /// Creates a new dummy cancelable.
    public init() {}

    /// Cancels the cancelable.
    public func cancel() {}
}
