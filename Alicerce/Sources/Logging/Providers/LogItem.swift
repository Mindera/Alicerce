//
//  LogItem.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

final class LogItem {
    
    let level: Log.Level
    let message: String
    let file: String
    let thread: String
    let function: String
    let line: Int
    
    init(level: Log.Level, message: String, file: String, thread: String, function: String, line: Int) {
        self.level = level
        self.message = message
        self.file = file
        self.thread = thread
        self.function = function
        self.line = line
    }
}
