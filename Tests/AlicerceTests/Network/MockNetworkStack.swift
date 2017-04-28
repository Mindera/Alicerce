//
//  MockNetworkStack.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation
@testable import Alicerce

final class MockNetworkStack: NetworkStack {

    var mockData: Data?
    var mockError: Network.Error?

    init(mockData: Data?, mockError: Network.Error?) {
        precondition(mockData != nil || mockError != nil)

        self.mockData = mockData
        self.mockError = mockError
    }

    func fetch<R: NetworkResource>(resource: R, _ completion: @escaping Network.CompletionClosure) {
        if let error = mockError {
            completion( { throw error } )
        } else if let data = mockData {
            completion( { return data } )
        } else {
            fatalError("🔥: either `mockData` or `mockError` must be defined!")
        }
    }
}
