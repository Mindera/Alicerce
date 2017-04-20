//
//  Log+Item.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

public extension Log {

    public struct Item {
        public let level: Level
        public let message: String
        public let file: StaticString
        public let thread: String
        public let function: StaticString
        public let line: UInt
    }
}
