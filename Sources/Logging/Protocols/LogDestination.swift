//
//  LogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol LogDestination: class {

    var minLevel: Log.Level { get }
    var formatter: LogItemFormatter { get }
    var instanceId: String { get }
    var queue: Log.Queue { get }

    func write(item: Log.Item)
}

public protocol LogDestinationFallible: LogDestination {

    var errorClosure: ((LogDestination, Log.Item, Error) -> ())? { get set }
}

extension LogDestination {

    public var instanceId: String {
        return "\(type(of: self))"
    }
}
