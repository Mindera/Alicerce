import Foundation
@testable import Alicerce

final class MockPersistenceStack<Key: Hashable, Payload, PersistenceError: Error>: PersistenceStack {

    typealias Key = Key
    typealias Payload = Payload
    typealias Error = PersistenceError

    var mockObject: (Key, @escaping ReadCompletionClosure) -> Void = { _, completion in completion(.success(nil)) }

    var mockSetObject: (Payload, Key, @escaping WriteCompletionClosure) -> Void = { _, _, completion in
        completion(.success(()))
    }

    var mockRemoveObject: (Key, @escaping WriteCompletionClosure) -> Void = { _, completion in
        completion(.success(()))
    }

    var mockRemoveAll: (@escaping WriteCompletionClosure) -> Void = { completion in completion(.success(())) }

    func object(for key: Key, completion: @escaping ReadCompletionClosure) {

        mockObject(key, completion)
    }

    func setObject(_ object: Payload, for key: Key, completion: @escaping WriteCompletionClosure) {

        mockSetObject(object, key, completion)
    }

    func removeObject(for key: Key, completion: @escaping WriteCompletionClosure) {

        mockRemoveObject(key, completion)
    }

    func removeAll(completion: @escaping WriteCompletionClosure) {

        mockRemoveAll(completion)
    }
}
 
