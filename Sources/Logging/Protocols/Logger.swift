//
//  Logger.swift
//  Alicerce
//
//  Created by Meik Schutz on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

protocol Logger {

    // MARK:- Logging

    func verbose(_ message: @autoclosure () -> String,
                 file: StaticString,
                 function: StaticString,
                 line: UInt)

    func debug(_ message: @autoclosure () -> String,
               file: StaticString,
               function: StaticString,
               line: UInt)

    func info(_ message: @autoclosure () -> String,
              file: StaticString,
              function: StaticString,
              line: UInt)

    func warning(_ message: @autoclosure () -> String,
                 file: StaticString,
                 function: StaticString,
                 line: UInt)

    func error(_ message: @autoclosure () -> String,
               file: StaticString,
               function: StaticString,
               line: UInt)
    
    func log(level: Log.Level,
             message: @autoclosure () -> String,
             file: StaticString,
             function: StaticString,
             line: UInt)
}
