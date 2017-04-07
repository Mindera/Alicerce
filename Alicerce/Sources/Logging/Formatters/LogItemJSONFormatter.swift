//
//  LogItemJSONFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public struct LogItemJSONFormatter: LogItemFormatter {

    public func format(logItem: LogItem) -> String {

        let dict: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "level": logItem.level.rawValue,
            "message": logItem.message,
            "thread": logItem.thread,
            "file": logItem.file,
            "function": logItem.function,
            "line": logItem.line
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            assertionFailure("failed to convert log item dictionay into JSON data object");
            return ""
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            assertionFailure("failed to convert log item JSON data object into a string object");
            return ""
        }

        return jsonString
    }
}
