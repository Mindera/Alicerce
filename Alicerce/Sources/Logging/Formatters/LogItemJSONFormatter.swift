//
//  LogItemJSONFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class LogItemJSONFormatter {

}

// MARK:- LogItemFormatter

extension LogItemJSONFormatter: LogItemFormatter {

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

        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []) else { return "" }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return "" }
        return jsonString
    }
}
