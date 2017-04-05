//
//  LevelColorFormatterProtocol.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

protocol LevelColorFormatterProtocol {
    
    var escape: String { get }
    var reset: String { get }
    
    func colorStringForLevel(_ level: Log.Level) -> String
}
