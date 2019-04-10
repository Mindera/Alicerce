import Foundation

/// A type representing a resource that provides a base request to be fetched.
public protocol BaseRequestResource: RequestResource {

    /// The resource's base request.
    var baseRequest: Request { get }
}
