import Foundation

/// A type representing a resource which can decode external representations into internal ones.
public protocol DecodableResource: ExternalResource {

    /// A resource's decode closure, invoked to convert an external representation into an internal one.
    typealias DecodeClosure = (External) throws -> Internal

    /// A resource's decode closure, invoked to convert an external representation into an internal one.
    var decode: DecodeClosure { get }
}

/// A type representing a resource which can encode internal representations into external ones.
public protocol EncodableResource: ExternalResource {

    /// A resource's encode closure, invoked to convert an internal representation into an external one.
    typealias EncodeClosure = (Internal) throws -> External

    /// The resource's encode closure, invoked to convert an internal representation into an external one.
    var encode: EncodeClosure { get }
}

/// A type representing a resource that can both decode external representations into internal ones an encode internal
/// representations into external ones.
public protocol CodableResource: DecodableResource & EncodableResource {}
