//
//  RequestHandler.swift
//  Alicerce
//
//  Created by Luís Portela on 29/06/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol RequestHandler {
    func handle(request: URLRequest)
    func request(_ request: URLRequest, handleResponse response: URLResponse?, error: Error?)
}
