import Foundation

/// A type representing a resource.
public protocol Resource {

    /// A resource's remote value type.
    associatedtype Remote

    /// A resource's local value type.
    associatedtype Local

    /// A resource's mapping closure, invoked to convert one type to another.
    typealias MapClosure<U, V> = (U) throws -> V

    /// A resource's parse closure, invoked to convert a remote value into a local one.
    typealias ParseClosure = MapClosure<Remote, Local>

    /// A resource's serialize closure, invoked to convert a local value into a remote one.
    typealias SerializeClosure = MapClosure<Local, Remote>

    /// A resource's parse closure, invoked to convert a remote value into a local one.
    var parse: ParseClosure { get }

    /// The resource's serialize closure, invoked to convert a local value into a remote one.
    var serialize: SerializeClosure { get }
}
