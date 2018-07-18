import Foundation

public typealias PersistenceCompletionClosure<R> = (_ inner: () throws -> R) -> Void

public protocol PersistenceStack {
    associatedtype Remote

    func object(for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Remote>)

    func setObject(_ object: Remote, for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Void>)

    func removeObject(for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Void>)
}
