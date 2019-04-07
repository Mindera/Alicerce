import Foundation

/// A type representing a resource that can decode custom errors from external representations and metadata.
public protocol ExternalErrorDecoderResource: ExternalResource {

    /// A type representing the custom error.
    associatedtype Error: Swift.Error

    /// A type representing external metadata (e.g. response object).
    associatedtype ExternalMetadata

    /// A resource's custom error decode closure, invoked when a fetch fails in an attempt to extract a custom error
    /// (e.g. extract API specific error after a HTTP protocol error).
    typealias DecodeErrorClosure = (External?, ExternalMetadata) -> Error?

    /// The resource's custom error decode closure, invoked when a fetch fails in an attempt to extract a custom error
    /// (e.g. extract API specific error after a HTTP protocol error).
    var decodeError: DecodeErrorClosure { get }
}
