//
//  MockPersistenceStack.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation
@testable import Alicerce

final class MockPersistenceStack: PersistenceStack {

    typealias InnerCompletionClosure<R> = () throws -> R
    typealias CompletionClosure<R> = (_ inner: InnerCompletionClosure<R>) -> Void

    var mockObjectCompletion: InnerCompletionClosure<Data> = { throw Persistence.Error.noObjectForKey }
    var mockSetObjectCompletion: InnerCompletionClosure<Void> = { return () }
    var mockRemoveObjectCompletion: InnerCompletionClosure<Void> = { return () }

    func object(for key: Persistence.Key, completion: @escaping CompletionClosure<Data>) {
        DispatchQueue.global(qos: .default).async {
            completion(self.mockObjectCompletion)
        }
    }

    func setObject(_ object: Data, for key: Persistence.Key, completion: @escaping CompletionClosure<Void>) {
        DispatchQueue.global(qos: .default).async {
            completion(self.mockSetObjectCompletion)
        }
    }

    func removeObject(for key: String, completion: @escaping CompletionClosure<Void>) {
        DispatchQueue.global(qos: .default).async {
            completion(self.mockRemoveObjectCompletion)
        }
    }
}
 
