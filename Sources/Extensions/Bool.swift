//
//  Bool.swift
//  Alicerce
//
//  Created by David Beleza on 25/01/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

public extension Bool {
    // Thanks to: https://www.objc.io/blog/2018/01/16/toggle-extension-on-bool/
    /// Helper to toggle a boolean value
    mutating func toggle() {
        self = !self
    }
}
