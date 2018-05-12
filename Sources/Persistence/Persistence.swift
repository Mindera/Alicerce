//
//  Persistence.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public enum Persistence {

    public typealias Key = String

    public enum Error: Swift.Error {
        case noObjectForKey
        case other(Swift.Error)
    }
}
