import Foundation
import Result

public protocol PersistenceStack {
    associatedtype Remote
    associatedtype Error: Swift.Error

    typealias ReadCompletionClosure = (_ result: Result<Remote?, Error>) -> Void
    typealias WriteCompletionClosure = (_ result: Result<Void, Error>) -> Void

    func object(for key: Persistence.Key, completion: @escaping ReadCompletionClosure)

    func setObject(_ object: Remote, for key: Persistence.Key, completion: @escaping WriteCompletionClosure)

    func removeObject(for key: Persistence.Key, completion: @escaping WriteCompletionClosure)

    func removeAll(completion: @escaping WriteCompletionClosure)
}
