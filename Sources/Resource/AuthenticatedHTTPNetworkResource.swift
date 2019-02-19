import Foundation
import struct Result.AnyError

/// A type representing a resource that is fetched via HTTP using a specific type of endpoint requiring authentication.
public protocol AuthenticatedHTTPNetworkResource: HTTPNetworkResource {

    /// A type that represents a request authenticator.
    associatedtype Authenticator: RequestAuthenticator where Authenticator.Request == Request

    /// The resource's request authenticator.
    var authenticator: Authenticator { get }
}

extension AuthenticatedHTTPNetworkResource {

    @discardableResult
    public func makeRequest(_ handler: @escaping MakeRequestHandler) -> Cancelable {

        return authenticator.authenticate(endpoint.request) { handler($0.mapError { AnyError($0) }) }
    }
}
