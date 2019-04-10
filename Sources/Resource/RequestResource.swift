import Foundation

/// A type representing a resource that is fetched by a request.
public protocol RequestResource: ExternalResource {

    /// A type representing a request.
    associatedtype Request
}
