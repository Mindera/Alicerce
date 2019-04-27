import Foundation

/// A type representing a network resource that can be retried after failing.
public protocol RetryableNetworkResource: RetryableResource & NetworkResource
where RetryMetadata == (request: Request, payload: External?, response: Response?) {}
