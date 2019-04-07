import Foundation

/// A type representing a resource that contains an empty external instance, to be used when an external representation
/// must be returned (e.g. returning a non `nil` value on 204's HTTP status codes).
public protocol EmptyExternalResource: ExternalResource {

    /// An empty instance of the resource's external representation (e.g. used for returning a value on 204's HTTP
    /// status codes).
    static var empty: External { get }
}
