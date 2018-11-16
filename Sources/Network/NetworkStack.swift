import Foundation

public protocol NetworkStack: class {
    associatedtype Remote
    associatedtype Request
    associatedtype Response

    func fetch<R>(resource: R, completion: @escaping Network.CompletionClosure<R.Remote>) -> Cancelable
    where R: NetworkResource & RetryableResource, R.Remote == Remote, R.Request == Request, R.Response == Response
}
