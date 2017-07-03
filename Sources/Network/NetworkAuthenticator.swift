//
//  Authenticator.swift
//  Alicerce
//
//  Created by Luís Portela on 03/07/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol NetworkAuthenticator {
    func authenticate(request: URLRequest, _ completion: @escaping (URLRequest) -> Void)

    func shouldRetry(with data: Data?, response: HTTPURLResponse?, error: Swift.Error?) -> Bool
}

public extension NetworkAuthenticator {
    func authenticate(request: URLRequest, _ completion: @escaping (URLRequest) -> Void) {
        completion(request)
    }

    func shouldRetry(with data: Data?, response: HTTPURLResponse?, error: Swift.Error?) -> Bool {
        guard error == nil else { return false }

        guard let response = response else { return false }

        return response.statusCode == 403
    }
}
