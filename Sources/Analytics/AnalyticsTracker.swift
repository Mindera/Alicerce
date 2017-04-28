//
//  AnalyticsTracker.swift
//  Alicerce
//
//  Created by Luís Portela on 26/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol AnalyticsTracker {
    
    /// Tracks a PageView
    ///
    /// - Parameter page: A Page with name and parameters if any
    func track(page: Analytics.Page)
    
    /// Tracks an Event
    ///
    /// - Parameter event: An Event with name and parameters if any
    func track(event: Analytics.Event)
}
