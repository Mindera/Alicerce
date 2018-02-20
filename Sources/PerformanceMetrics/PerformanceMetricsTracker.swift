//
//  PerformanceMetricsTracker.swift
//  Alicerce
//
//  Created by Luís Portela on 15/12/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol PerformanceMetricsTracker: class {
    func begin(with identifier: PerformanceMetrics.Identifier)
    func end(with identifier: PerformanceMetrics.Identifier, metadata: PerformanceMetrics.Metadata?)
}
