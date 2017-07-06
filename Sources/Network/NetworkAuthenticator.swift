//
//  NetworkAuthenticator.swift
//  Alicerce
//
//  Created by Luís Portela on 03/07/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol NetworkAuthenticator {
    func authenticate(request: URLRequest, _ performRequest: @escaping (URLRequest) -> Cancelable) -> Cancelable

    func shouldRetry(with data: Data?, response: HTTPURLResponse?, error: Swift.Error?) -> Bool
}
