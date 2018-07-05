import Foundation
@testable import Alicerce

final class MockPersistenceStack: PersistenceStack {

    typealias InnerCompletionClosure<R> = () throws -> R
    typealias CompletionClosure<R> = (_ inner: InnerCompletionClosure<R>) -> Void

    var objectInvokedClosure: ((Persistence.Key, CompletionClosure<Data>) -> Void)?
    var setObjectInvokedClosure: ((Data, Persistence.Key, CompletionClosure<Void>) -> Void)?
    var removeObjectInvokedClosure: ((String, CompletionClosure<Void>) -> Void)?

    var mockObjectCompletion: InnerCompletionClosure<Data> = { throw Persistence.Error.noObjectForKey }
    var mockSetObjectCompletion: InnerCompletionClosure<Void> = { return () }
    var mockRemoveObjectCompletion: InnerCompletionClosure<Void> = { return () }

    func object(for key: Persistence.Key, completion: @escaping CompletionClosure<Data>) {
        objectInvokedClosure?(key, completion)
        completion(mockObjectCompletion)
    }

    func setObject(_ object: Data, for key: Persistence.Key, completion: @escaping CompletionClosure<Void>) {
        setObjectInvokedClosure?(object, key, completion)
        completion(mockSetObjectCompletion)
    }

    func removeObject(for key: String, completion: @escaping CompletionClosure<Void>) {
        removeObjectInvokedClosure?(key, completion)
        completion(mockRemoveObjectCompletion)
    }
}
 
