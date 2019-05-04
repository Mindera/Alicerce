import Foundation

/// A type representing a resource that is fetched via HTTP using a specific type of endpoint.
public protocol HTTPNetworkResource: NetworkResource & BaseRequestResource where Request == URLRequest {

    /// A type that represents an HTTP endpoint.
    associatedtype Endpoint: HTTPResourceEndpoint

    /// The resource's endpoint.
    var endpoint: Endpoint { get }
}

public extension HTTPNetworkResource {

    var baseRequest: Request { return endpoint.request }
}
