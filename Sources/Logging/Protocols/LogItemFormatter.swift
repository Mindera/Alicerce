//
//  LogItemFormatter.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

public protocol LogItemFormatter {
    func format(logItem: Log.Item) -> String
}


