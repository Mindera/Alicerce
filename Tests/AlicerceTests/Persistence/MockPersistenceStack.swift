import Foundation
import Result
@testable import Alicerce

final class MockPersistenceStack: PersistenceStack {

    typealias Remote = Data

    enum Error: Swift.Error { case 💥 }

    var objectInvokedClosure: ((Persistence.Key, ReadCompletionClosure) -> Void)?
    var setObjectInvokedClosure: ((Remote, Persistence.Key, WriteCompletionClosure) -> Void)?
    var removeObjectInvokedClosure: ((Persistence.Key, WriteCompletionClosure) -> Void)?
    var removeAllInvokedClosure: ((WriteCompletionClosure) -> Void)?

    var mockObjectResult: Result<Remote?, Error> = .success(nil)
    var mockSetObjectResult: Result<Void, Error> = .success(())
    var mockRemoveObjectResult: Result<Void, Error> = .success(())
    var mockRemoveAllResult: Result<Void, Error> = .success(())

    func object(for key: Persistence.Key, completion: @escaping ReadCompletionClosure) {
        objectInvokedClosure?(key, completion)
        completion(mockObjectResult)
    }

    func setObject(_ object: Remote, for key: Persistence.Key, completion: @escaping WriteCompletionClosure) {
        setObjectInvokedClosure?(object, key, completion)
        completion(mockSetObjectResult)
    }

    func removeObject(for key: Persistence.Key, completion: @escaping WriteCompletionClosure) {
        removeObjectInvokedClosure?(key, completion)
        completion(mockRemoveObjectResult)
    }

    func removeAll(completion: @escaping WriteCompletionClosure) {
        removeAllInvokedClosure?(completion)
        completion(mockRemoveAllResult)
    }
}
 
