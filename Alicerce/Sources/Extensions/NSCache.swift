//
//  NSCache.swift
//  Alicerce
//
//  Created by Luís Afonso on 18/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

// FIX: We cannot to this for now https://swift.org/migration-guide/
// Search for: After migration to Swift 3, you may see an error like “Extension of a generic Objective-C class cannot access the class’s generic parameters at runtime”.
public extension NSCache {
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
