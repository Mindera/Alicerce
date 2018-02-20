//
//  NetworkAuthenticator.swift
//  Alicerce
//
//  Created by Luís Portela on 03/07/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol NetworkAuthenticator {
    typealias PerformRequestClosure = (_ inner: () throws -> URLRequest) -> Cancelable

    func authenticate(request: URLRequest, performRequest: @escaping PerformRequestClosure) -> Cancelable

    func isAuthenticationInvalid(for request: URLRequest,
                                 data: Data?,
                                 response: HTTPURLResponse?,
                                 error: Swift.Error?) -> Bool
}
