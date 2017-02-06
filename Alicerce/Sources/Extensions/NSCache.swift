//
//  NSCache.swift
//  Alicerce
//
//  Created by Luís Afonso on 18/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

extension NSCache {
    subscript(key: KeyType) -> ObjectType? {
        get {
            return object(forKey: key)
        }
        set {
            if let value = newValue {
                setObject(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}
