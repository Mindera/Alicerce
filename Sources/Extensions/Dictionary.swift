import Foundation

// MARK: - Transform

public extension Dictionary {

    /// Map the receiver into another dictionary of type `[K : V]` using the given `transform` closure. As the
    /// dictionary is built, the initializer calls the `combine` closure with the current and new values for any
    /// duplicate keys.
    ///
    /// - parameter transform: the transformation closure to convert key-value pairs.
    ///             combine: A closure that is called with the values for any duplicate keys that are encountered. The
    ///             closure returns the desired value for the final dictionary.
    ///
    /// - returns: a new dictionary with the mapped key-values.
    func mapKeysAndValues<K: Hashable, V>(_ transform: (Element) throws -> (K, V),
                                          uniquingKeysWith combine: (V, V) throws -> V) rethrows -> [K : V] {
        var result: [K : V] = [:]
        for element in self {
            let (newK, newV) = try transform(element)
            if let existingV = result[newK] {
                result[newK] = try combine(existingV, newV)
            } else {
                result[newK] = newV
            }
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
        return Dictionary(uniqueKeysWithValues: flattenedKeysAndValues(keySeparator: keySeparator))
    }

    /// Flatten the receiver after recursively unnesting any dictionaries of type `[String : Value]` contained inside 
    /// it and returning an `[(Key, Value)]`. The keys are concatenated using `keySeparator`.
    /// This is an auxiliary method to `flattened`.
    ///
    /// - Parameters:
    ///   - parentKey: the key of the parent dictionary
    ///   - keySeparator: the separator to use when concatenating keys (defaults to `"."`)
    /// - Returns: a copy of the receiver as an array of key-value tuples after flattening all nested dictionaries
    private func flattenedKeysAndValues(parentKey: Key? = nil, keySeparator: String = ".") -> [(Key, Value)] {
        func tuplify(key: Key, value: Value) -> [(Key, Value)] {
            let newKey: String

            if let parentKey = parentKey {
                newKey = parentKey + keySeparator + key
            } else {
                newKey = key
            }

            switch value {
            case let dictionary as [Key : Value]:
                return dictionary.flattenedKeysAndValues(parentKey: newKey)
            default:
                return [(key: newKey, value : value)]
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
    func removingValues<S: Sequence>(forKeys keys: S) -> [Key : Value] where S.Iterator.Element == Key {
        var copy = self
        keys.forEach { copy.removeValue(forKey: $0) }
        return copy
    }

    /// Remove multiple keys from the receiver in place, and return the removed values.
    ///
    /// - parameter keys: a sequence of keys to remove.
    ///
    /// - returns: the values associated with the removed keys.
    mutating func removeValues<S: Sequence>(forKeys keys: S) -> [Key : Value?] where S.Iterator.Element == Key {
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
    subscript(keys: Key...) -> [Value?] {
        return keys.map { self[$0] }
    }

    /// Return the values associated to multiple keys, as an array of optionals. The keys are evaluated in order, and
    /// either the corresponding value or `nil` is be appended to the result, depending if the key is present or not.
    /// The returned array has the same element count as the given keys sequence.
    ///
    /// - parameter keys: the keys to retrieve.
    ///
    /// - returns: an array of optional `Value`s, in the same order as the keys.
    subscript<S: Sequence>(keys: S) -> [Value?] where S.Iterator.Element == Key {
        return keys.map { self[$0] }
    }
}
