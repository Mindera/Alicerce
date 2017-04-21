//
//  Network.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public enum Network {

    // MARK: - TypeAlias

    public typealias CompletionClosure = (_ inner: () throws -> Data) -> Void

    // MARK: - Network Error

    public enum Error: Swift.Error {
        case http(code: HTTP.StatusCode, description: String?)
        case noData
        case url(Swift.Error)
        case badResponse
    }

    // MARK: - Network Configuration
    
    public struct Configuration {
        let baseURL: URL
        let sessionConfiguration: URLSessionConfiguration
        let delegateQueue: OperationQueue?

        public init(baseURL: URL,
                    sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                    delegateQueue: OperationQueue? = nil) {

            self.baseURL = baseURL
            self.sessionConfiguration = sessionConfiguration
            self.delegateQueue = delegateQueue
        }
    }
}
