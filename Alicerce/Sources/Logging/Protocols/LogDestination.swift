//
//  LogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

public protocol LogDestination {

    var minLevel: Log.Level { get set }
    var formatter: LogItemFormatter { get set }
    var instanceId: String { get }

    func write(item: Log.Item)
}

extension LogDestination {

    public var instanceId: String {
        return "\(type(of: self))"
    }
}
