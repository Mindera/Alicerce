import Foundation

/// A type that can be cancelled.
public protocol Cancelable {

    /// Cancels the cancelable.
    func cancel()
}

// MARK: - Extensions

extension URLSessionTask: Cancelable {}

extension DispatchWorkItem: Cancelable {}

// MARK: - Wrapper Cancelables

/// A cancelable reference type.
public typealias CancelableClass = Cancelable & AnyObject

/// A cancelable that wraps another cancelable as a weak reference.
public final class WeakCancelable: Cancelable {

    /// The wrapped (weak) cancelable.
    private weak var cancelable: CancelableClass?

    /// Creates a new cancelable wrapping another one as a weak reference.
    ///
    /// - Parameter cancelable: The wrapped cancelable.
    public init(_ cancelable: CancelableClass) {
        self.cancelable = cancelable
    }

    /// Cancels the cancelable.
    public func cancel() {
        cancelable?.cancel()
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

    /// Adds a cancelable to the bag, if it hasn't been cancelled yet.
    ///
    /// - Parameters:
    ///   - cancelable: The cancelable to add.
    public func add(cancelable: Cancelable) {
        guard isCancelled == false else { return }

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
public struct DummyCancelable: Cancelable {

    /// Creates a new dummy cancelable.
    public init() {}

    /// Cancels the cancelable.
    public func cancel() {}
}
