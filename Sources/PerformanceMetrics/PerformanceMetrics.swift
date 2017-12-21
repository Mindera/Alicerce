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

    private lazy var trackers = [PerformanceMetricsTracker]()

    public init() {}

    public func add(tracker: PerformanceMetricsTracker) {
        trackers.append(tracker)
    }

    public func remove(tracker: PerformanceMetricsTracker) {
        trackers = trackers.filter { $0 !== tracker }
    }

    // Measurement API

    public func measure<T>(with identifier: Identifier, measureBlock: () throws -> T) rethrows -> T {
        begin(with: identifier)

        let measureResult = try measureBlock()

        end(with: identifier)

        return measureResult
    }

    public func measureAsync<T>(with identifier: Identifier,
                                measureBlock: (_ end: () -> Void) throws -> T) rethrows -> T {
        let end: () -> Void = { [weak self] in
            self?.end(with: identifier)
        }

        begin(with: identifier)

        return try measureBlock(end)
    }
}

extension PerformanceMetrics: PerformanceMetricsTracker {

    public func begin(with identifier: PerformanceMetrics.Identifier) {
        let trackersCopy = trackers

        trackersCopy.forEach { $0.begin(with: identifier) }
    }

    public func end(with identifier: PerformanceMetrics.Identifier) {
        let trackersCopy = trackers

        trackersCopy.forEach { $0.end(with: identifier) }
    }
}
