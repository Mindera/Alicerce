/// An arbitrary container (and property wrapper) which stores a **mutable** value of type `T`.
///
/// The main purpose of this object is to encapsulate value types so that they can be used like a reference type
/// (e.g. pass value types around without copying them, memoize value types inside closures via capture list, etc)
@propertyWrapper
@dynamicMemberLookup
public final class Box<T> {

    /// The wrapped value.
    public var wrappedValue: T

    /// Instantiate a new mutable value box with the given value.
    ///
    /// - parameter wrappedValue: the value to encapsulate.
    ///
    /// - returns: a newly instantiated box with the encapsulated value.
    public init(wrappedValue: T) { self.wrappedValue = wrappedValue }

    public subscript<U>(dynamicMember keyPath: KeyPath<T, U>) -> U { wrappedValue[keyPath: keyPath] }
}

extension Box {

    /// The wrapped value (compact).
    public var value: T {
        get { wrappedValue }
        set { wrappedValue = newValue }
    }

    /// Instantiate a new mutable value box with the given value (compact).
    ///
    /// - parameter wrappedValue: the value to encapsulate.
    ///
    /// - returns: a newly instantiated box with the encapsulated value.
    public convenience init(_ value: T) { self.init(wrappedValue: value) }
}

@available(*, unavailable, renamed: "Box")
public typealias VarBox<T> = Box<T>
