//
//  LevelNameFormatterProtocol.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

protocol LevelNameFormatterProtocol {
    func labelStringForLevel(_ level: Log.Level) -> String
}
