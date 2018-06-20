import Foundation

public protocol NetworkStack {
    associatedtype Remote

    func fetch<R: NetworkResource>(resource: R, completion: @escaping Network.CompletionClosure<R.Remote>)
    -> Cancelable where R.Remote == Remote
}
