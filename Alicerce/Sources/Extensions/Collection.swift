//
//  Collection.swift
//  Alicerce
//
//  Created by Luís Afonso on 18/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

// MARK: - Array

func -<Key: Hashable, Value: AnyObject>(left: [[Key : Value]], right: [[Key : Value]]) -> [[Key : Value]] {
    var final = left
    
    for (index, element) in right.enumerated() {
        final[index] = (left[index] - element)
    }
    
    return final
}

// MARK: - Dictionary

func -<Key: Hashable, Value: AnyObject>(left: [Key : Value], right: [Key : Value]) -> [Key : Value] {
    var final = left
    
    for (key, value) in right {
        if let val = left[key], val === value {
            final[key] = nil
        }
    }
    
    return final
}

func +<Key, Value>(left: [Key : Value], right: [Key : Value]) -> [Key : Value] {
    var final = left
    
    for (key, value) in right {
        final[key] = value
    }
    
    return final
}

func +=<Key, Value>(left: inout [Key : Value], right: [Key : Value]) {
    for (key, value) in right {
        left[key] = value
    }
}
