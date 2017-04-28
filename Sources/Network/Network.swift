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
    public typealias AuthenticationCompletionClosure = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    public typealias AuthenticationChallengeValidatorClosure = (URLAuthenticationChallenge, AuthenticationCompletionClosure) -> Void

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

        // TODO: add better server trust validator
        let authenticationChallengeValidator: AuthenticationChallengeValidatorClosure?

        public init(baseURL: URL, authenticationChallengeValidator: AuthenticationChallengeValidatorClosure? = nil) {
            self.baseURL = baseURL
            self.authenticationChallengeValidator = authenticationChallengeValidator
        }
    }
}
