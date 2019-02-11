import Foundation

/// A type representing a resource that is fetched via HTTP using a specific type of endpoint.
public protocol HTTPNetworkResource: NetworkResource where Request == URLRequest {

    /// A type that represents an HTTP endpoint.
    associatedtype Endpoint: HTTPResourceEndpoint

    /// The resource's endpoint.
    var endpoint: Endpoint { get }
}

extension HTTPNetworkResource {

    @discardableResult
    public func makeRequest(_ handler: @escaping MakeRequestHandler) -> Cancelable {

        return handler(.success(endpoint.request))
    }
}
