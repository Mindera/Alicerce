//
//  LogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol LogDestination {

    var minLevel: Log.Level { get set }
    var formatter: LogItemFormatter { get set }
    var instanceId: String { get }
    var dispatchQueue: DispatchQueue { get }

    func write(item: Log.Item)
}

extension LogDestination {

    public var instanceId: String {
        return "\(type(of: self))"
    }
}
