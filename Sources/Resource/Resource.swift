import Foundation

/// A type representing a resource.
public protocol Resource {

    /// A resource's internal representation type.
    associatedtype Internal
}

/// A type representing a resource with an external representation.
public protocol ExternalResource: Resource {

    /// A resource's external representation type.
    associatedtype External
}
