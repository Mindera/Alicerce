//
//  Logger.swift
//  Alicerce
//
//  Created by Meik Schutz on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

protocol Logger {

    // MARK:- Destination Management

    func register(_ destination: LogDestination)
    func unregister(_ destination: LogDestination)
    func removeAllDestinations()

    // MARK:- Logging

    func verbose(_ message: @autoclosure () -> String,
                 file: String,
                 function: String,
                 line: Int)

    func debug(_ message: @autoclosure () -> String,
               file: String,
               function: String,
               line: Int)

    func info(_ message: @autoclosure () -> String,
              file: String,
              function: String,
              line: Int)

    func warning(_ message: @autoclosure () -> String,
                 file: String,
                 function: String,
                 line: Int)

    func error(_ message: @autoclosure () -> String,
               file: String,
               function: String,
               line: Int)
    
    func log(level: Log.Level,
             message: @autoclosure () -> String,
             file: String,
             function: String,
             line: Int)
}
