//
//  LogProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

public protocol LogProvider {

    var minLevel: Log.Level { get set }
    var formatter: LogItemFormatter { get set }
    var providerInstanceId: String { get }

    func write(item: Log.Item)
}
