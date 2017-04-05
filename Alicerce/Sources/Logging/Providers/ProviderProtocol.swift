//
//  ProviderProtocol.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

protocol ProviderProtocol {
    
    var minLevel: Log.Level { get set }
    var formatter: LogItemFormatterProtocol { get set }
    
    func providerInstanceId() -> String
    func write(item: LogItem)
}
