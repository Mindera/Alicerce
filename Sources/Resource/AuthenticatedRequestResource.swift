import Foundation

/// A type representing a resource that authenticates requests to be fetched.
public protocol AuthenticatedRequestResource: RequestResource {

    /// A type that represents a request authenticator.
    associatedtype Authenticator: RequestAuthenticator where Authenticator.Request == Request

    /// The resource's request authenticator.
    var authenticator: Authenticator { get }
}
