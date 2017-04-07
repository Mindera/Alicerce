//
//  Log+Item.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

public extension Log {

    public struct Item {

        public let level: Log.Level
        public let message: String
        public let file: String
        public let thread: String
        public let function: String
        public let line: Int

        public init(level: Log.Level, message: String, file: String, thread: String, function: String, line: Int) {
            self.level = level
            self.message = message
            self.file = file
            self.thread = thread
            self.function = function
            self.line = line
        }
    }
}
