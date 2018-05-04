//
//  Log+JSONLogItemFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public struct JSONLogItemFormatter: LogItemFormatter {

        public enum LogKey {
            static let timestamp = "timestamp"
            static let level = "level"
            static let message = "message"
            static let thread = "thread"
            static let file = "file"
            static let function = "function"
            static let line = "line"
        }

        private let dateEncoder: (Date) -> Any
        private let levelEncoder: (Level) -> Any

        init(dateEncoder: @escaping (Date) -> Any = { $0.timeIntervalSince1970 },
             levelEncoder: @escaping (Level) -> Any = { $0.rawValue }) {
            self.dateEncoder = dateEncoder
            self.levelEncoder = levelEncoder
        }

        public func format(logItem: Item) -> String {

            let dict: JSON.Dictionary = [
                LogKey.timestamp: dateEncoder(Date()),
                LogKey.level: levelEncoder(logItem.level),
                LogKey.message: logItem.message,
                LogKey.thread: logItem.thread,
                LogKey.file: logItem.file,
                LogKey.function: logItem.function,
                LogKey.line: logItem.line
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
                assertionFailure("failed to convert log item dictionay into JSON data object")
                return ""
            }

            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                assertionFailure("failed to convert log item JSON data object into a string object")
                return ""
            }
            
            return jsonString
        }
    }
}
