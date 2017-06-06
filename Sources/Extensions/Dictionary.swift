//
//  Dictionary.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

// MARK: - Create

public extension Dictionary {

    /// Instantiate a new dictionary from a sequence of key-value tuples of type `(key: Key, value: Value)`.
    ///
    /// - warning: the tuples are evaluated in order and an already existing key will be overwritten if another tuple
    /// has the same key.
    ///
    /// - parameter keyValueTuples: the sequence of key-value tuples to instantiate the dictionary with.
    ///
    /// - returns: a newly instantiated dictionary, from the provided key-value tuples.
    init<S: Sequence>(keyValueTuples: S) where S.Iterator.Element == Element {
        self.init()
        keyValueTuples.forEach { self[$0] = $1 }
    }

    /// Instantiate a new dictionary from a sequence of key-value tuples of type `(Key, Value)`.
    ///
    /// - warning: the tuples are evaluated in order and an already existing key will be overwritten if another tuple
    /// has the same key.
    ///
    /// - parameter keyValueTuples: the sequence of key-value tuples to instantiate the dictionary with.
    ///
    /// - returns: a newly instantiated dictionary, from the provided key-value tuples.
    init<S: Sequence>(keyValueTuples: S) where S.Iterator.Element == (Key, Value) {
        self.init()
        keyValueTuples.forEach { self[$0] = $1 }
    }
}

// MARK: - Merge

// Credits: Erica Sadun & Airspeed Velocity
// http://ericasadun.com/2015/07/08/swift-merging-dictionaries/

public extension Dictionary {

    /// Merge a dictionary of the same type given as parameter into the receiver.
    ///
    /// - parameter dictionary: the dictionary to be merged into the receiver.
    mutating func unionInPlace(dictionary: [Key : Value]) {
        for (key, value) in dictionary {
            self[key] = value
        }
    }

    /// Merge a `Sequence` with an element of type `(key: Key, value: Value)` given as parameter into the receiver.
    ///
    /// - parameter sequence: the sequence to be merged into the receiver.
    mutating func unionInPlace<S: Sequence>(sequence: S) where S.Iterator.Element == Element {
        for (key, value) in sequence {
            self[key] = value
        }
    }

    /// Merge a `Sequence` with an element of type `(Key, Value)` given as parameter into the receiver.
    ///
    /// - parameter sequence: the sequence to be merged into the receiver.
    mutating func unionInPlace<S: Sequence>(sequence: S) where S.Iterator.Element == (Key, Value) {
        for (key, value) in sequence {
            self[key] = value
        }
    }
}

// MARK: - Transform

public extension Dictionary {

    /// Map the receiver to another dictionary type `[K : V]` using a transformation closure.
    ///
    /// - warning: the receiver's key value elements are iterated and transformed one by one, which means that if the
    /// mapping closures resolves to an already used key, it will overwite any already present one.
    ///
    /// - parameter transform: the transformation closure to convert key-value pairs.
    ///
    /// - returns: a new dictionary with the mapped key-values.
    func map<K, V>(transform: (Key, Value) -> (K, V)) -> [K : V] {
        var result: [K : V] = [:]
        for (k, v) in self {
            let (newK, newV) = transform(k, v)
            result[newK] = newV
        }

        return result
    }
}

public extension Dictionary where Key == String {

    /// Return a copy of the receiver after being flattened by recursively unnesting any dictionaries of type
    /// `[String : Value]` contained inside it. The keys are concatenated using `keySeparator`.
    ///
    /// - Parameter keySeparator: the separator to use when concatenating keys (defaults to `"."`)
    /// - Returns: a copy of the receiver after flattening all nested dictionaries
    func flattened(keySeparator: String = ".") -> [Key : Value] {
        return Dictionary(keyValueTuples: self.flattenedKeyValueTuples(keySeparator: keySeparator))
    }

    /// Flatten the receiver after recursively unnesting any dictionaries of type `[String : Value]` contained inside 
    /// it and returning an `[(Key, Value)]`. The keys are concatenated using `keySeparator`.
    /// This is an auxiliary method to `flattened`.
    ///
    /// - Parameters:
    ///   - parentKey: the key of the parent dictionary
    ///   - keySeparator: the separator to use when concatenating keys (defaults to `"."`)
    /// - Returns: a copy of the receiver as an array of key-value tuples after flattening all nested dictionaries
    private func flattenedKeyValueTuples(parentKey: Key? = nil, keySeparator: String = ".") -> [(Key, Value)] {
        func tuplify(key: Key, value: Value) -> [(Key, Value)] {
            let newKey: String

            if let parentKey = parentKey {
                newKey = parentKey + keySeparator + key
            } else {
                newKey = key
            }

            switch value {
            case let dictionary as [Key : Value]:
                return dictionary.flattenedKeyValueTuples(parentKey: newKey)
            default:
                return [(key: newKey, value: value)]
            }
        }

        return map(tuplify).flatMap { $0 }
    }
}

// MARK: - Remove values

public extension Dictionary {

    /// Return a copy of the receiver after removing multiple keys.
    ///
    /// - parameter keys: the sequence of keys to remove.
    ///
    /// - returns: a copy of the receiver after removing all keys in `keys`
    func dictionaryByRemovingValuesForKeys<S: Sequence>(keys: S) -> [Key : Value] where S.Iterator.Element == Key {
        var copy = self
        keys.forEach { copy.removeValue(forKey: $0) }
        return copy
    }

    /// Remove multiple keys from the receiver in place, and return the removed values.
    ///
    /// - parameter keys: a sequence of keys to remove.
    ///
    /// - returns: the values associated with the removed keys.
    mutating func removeValuesForKeys<S: Sequence>(keys: S) -> [Key : Value?] where S.Iterator.Element == Key {
        var removed: [Key : Value?] = [:]
        keys.forEach { removed[$0] = removeValue(forKey: $0) }
        return removed
    }
}

// MARK: - Get values

public extension Dictionary {

    /// Return the values associated to multiple keys, as an array of optionals. The keys are evaluated in order, and
    /// either the corresponding value or `nil` is be appended to the result, depending if the key is present or not.
    /// The returned array has the same element count as the given keys sequence.
    ///
    /// - parameter keys: the keys to retrieve.
    ///
    /// - returns: an array of optional `Value`s, in the same order as the keys.
    func multiSubscript<S: Sequence>(keys: S) -> [Value?] where S.Iterator.Element == Key {
        var result = [Value?]()
        keys.forEach { result.append(self[$0]) }
        return result
    }
}
