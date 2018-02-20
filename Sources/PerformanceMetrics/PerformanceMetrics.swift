//
//  PerformanceMetrics.swift
//  Alicerce
//
//  Created by Luís Portela on 15/12/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class PerformanceMetrics {

    public typealias Identifier = String
    public typealias Metadata = [String : Any]

    private lazy var trackers = [PerformanceMetricsTracker]()

    public init() {}

    public func add(tracker: PerformanceMetricsTracker) {
        trackers.append(tracker)
    }

    public func remove(tracker: PerformanceMetricsTracker) {
        trackers = trackers.filter { $0 !== tracker }
    }

    // Measurement API

    public func measure<T>(with identifier: Identifier,
                           metadata: Metadata = [:],
                           measureBlock: () throws -> T) rethrows -> T {

        begin(with: identifier, metadata: metadata)

        let measureResult = try measureBlock()

        end(with: identifier, metadata: metadata)

        return measureResult
    }

    public func measureAsync<T>(with identifier: Identifier,
                                metadata: Metadata = [:],
                                measureBlock: (_ end: () -> Void) throws -> T) rethrows -> T {
        
        let end: () -> Void = { [weak self] in
            self?.end(with: identifier, metadata: metadata)
        }

        begin(with: identifier, metadata: metadata)

        return try measureBlock(end)
    }

    public func begin(with identifier: PerformanceMetrics.Identifier, metadata: Metadata = [:]) {
        trackers.forEach { $0.begin(with: identifier, metadata: metadata) }
    }
    
    public func end(with identifier: PerformanceMetrics.Identifier, metadata: Metadata = [:]) {
        trackers.forEach { $0.end(with: identifier, metadata: metadata) }
    }
}
