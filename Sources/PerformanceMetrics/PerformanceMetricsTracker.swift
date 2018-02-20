//
//  PerformanceMetricsTracker.swift
//  Alicerce
//
//  Created by Luís Portela on 15/12/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol PerformanceMetricsTracker: class {

    typealias Identifier = String
    typealias Metadata = [String : Any]

    func begin(with identifier: Identifier)
    func end(with identifier: Identifier, metadata: Metadata?)
}
