import Foundation

public protocol NetworkStack: AnyObject {
    
    associatedtype Remote
    associatedtype Request
    associatedtype Response

    typealias FetchResource = RetryableNetworkResource & EmptyExternalResource & ExternalErrorDecoderResource

    func fetch<R: FetchResource>(resource: R, completion: @escaping Network.CompletionClosure<R.External>) -> Cancelable
    where R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response
}
