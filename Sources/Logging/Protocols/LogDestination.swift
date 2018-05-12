//
//  LogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol LogDestination: class {

    typealias ID = String

    var minLevel: Log.Level { get }
    var formatter: LogItemFormatter { get }
    var id: ID { get }

    func write(item: Log.Item, failure: @escaping (Error) -> Void)
}

extension LogDestination {

    public var id: ID {
        return "\(type(of: self))"
    }
}
