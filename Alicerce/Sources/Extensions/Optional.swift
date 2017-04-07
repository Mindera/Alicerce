//
//  Optional.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Swift.Optional {
    public func then(f: (Wrapped) -> Void) {
        if let wrapped = self { f(wrapped) }
    }
}
