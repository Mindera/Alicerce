//
//  MockNetworkStack.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation
@testable import Alicerce

final class MockNetworkCancelable: Cancelable {

    var mockCancelClosure: (() -> Void)?

    public func cancel() {
        mockCancelClosure?()
    }
}

final class MockNetworkStack: NetworkStack {

    var mockData: Data?
    var mockError: Network.Error?
    var mockCancelable: MockNetworkCancelable = MockNetworkCancelable()

    let queue: DispatchQueue

    var beforeFetchCompletionClosure: (() -> Void)?
    var afterFetchCompletionClosure: (() -> Void)?

    init(mockData: Data? = nil, mockError: Network.Error? = nil, queue: DispatchQueue = DispatchQueue.global()) {

        self.mockData = mockData
        self.mockError = mockError
        self.queue = queue
    }

    func fetch<R: NetworkResource>(resource: R, _ completion: @escaping Network.CompletionClosure) -> Cancelable {
        queue.async {
            self.beforeFetchCompletionClosure?()

            if let error = self.mockError {
                completion( { throw error } )
            } else if let data = self.mockData {
                completion( { return data } )
            } else {
                fatalError("🔥: either `mockData` or `mockError` must be defined!")
            }

            self.afterFetchCompletionClosure?()
        }

        return mockCancelable
    }
}
