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

    public typealias CompletionClosure<R> = (_ inner: () throws -> R) -> Void
    public typealias AuthenticationCompletionClosure = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    // MARK: - Network Error

    public enum Error: Swift.Error {
        case http(code: HTTP.StatusCode, apiError: Swift.Error?)
        case noData
        case url(Swift.Error)
        case badResponse
        case authenticator(Swift.Error)
    }

    // MARK: - Network Configuration
    
    public struct Configuration {

        let authenticationChallengeHandler: AuthenticationChallengeHandler?

        let authenticator: NetworkAuthenticator?
        
        let requestInterceptors: [RequestInterceptor]

        public init(authenticationChallengeHandler: AuthenticationChallengeHandler? = nil,
                    authenticator: NetworkAuthenticator? = nil,
                    requestInterceptors: [RequestInterceptor] = []) {
            self.authenticationChallengeHandler = authenticationChallengeHandler
            self.authenticator = authenticator
            self.requestInterceptors = requestInterceptors
        }
    }
}
