//
//  Thread.swift
//  Alicerce
//
//  Created by Meik Schutz on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Thread {

    /// Returns the name of the thread or 'main-thread', if it's the application's main thread
    public class func threadName() -> String {

        guard !isMainThread else { return "main-thread" }

        if let threadName = current.name, !threadName.isEmpty {
            return threadName
        }
        else {
            return String(format: "%p", current)
        }
    }
}
