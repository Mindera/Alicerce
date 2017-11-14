//
//  RequestInterceptor.swift
//  Alicerce
//
//  Created by Luís Portela on 29/06/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol RequestInterceptor {
    func intercept(request: URLRequest)
    func intercept(response: URLResponse?, data: Data?, error: Error?, for request: URLRequest)
}
