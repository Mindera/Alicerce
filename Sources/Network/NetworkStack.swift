import Foundation

public protocol NetworkStack: AnyObject {

    associatedtype Remote
    associatedtype Request
    associatedtype Response
    associatedtype Error: Swift.Error

    typealias FetchResource = RetryableNetworkResource & EmptyExternalResource & ExternalErrorDecoderResource

    typealias FetchResult = Result<Network.Value<Remote, Response>, Error>

    typealias FetchCompletionClosure = (FetchResult) -> Void

    func fetch<R: FetchResource>(resource: R, completion: @escaping FetchCompletionClosure) -> Cancelable
    where R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response
}
