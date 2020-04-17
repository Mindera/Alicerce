import Foundation

public protocol PersistenceStack: AnyObject {

    associatedtype Key: Hashable
    associatedtype Payload
    associatedtype Error: Swift.Error

    typealias ReadCompletionClosure = (_ result: Result<Payload?, Error>) -> Void
    typealias WriteCompletionClosure = (_ result: Result<Void, Error>) -> Void

    func object(for key: Key, completion: @escaping ReadCompletionClosure)

    func setObject(_ object: Payload, for key: Key, completion: @escaping WriteCompletionClosure)

    func removeObject(for key: Key, completion: @escaping WriteCompletionClosure)

    func removeAll(completion: @escaping WriteCompletionClosure)
}
