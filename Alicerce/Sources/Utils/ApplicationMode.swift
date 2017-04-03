//
//  ApplicationMode.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

/// An enum representing the application's mode (Debug, Release).
public enum ApplicationMode: String {

    /// The application is running in Debug mode.
    case debug

    /// The application is running in Release mode.
    case release

    /// The current application's mode.
    static var current: ApplicationMode {
        #if DEBUG
            return .debug
        #else
            return .release
        #endif
    }
}
