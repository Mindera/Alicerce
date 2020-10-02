import Foundation

// Credits to @AirspeedVelocity 🙏
// https://stackoverflow.com/a/28898790/1921751

public extension Sequence {

    /// Returns the result of combining the elements of the sequence using the given combining closure, grouped by keys
    /// generated using the a grouping closure. The result is a dictionary of type `[K : U]`. An initial value should
    /// be given to be used as initial accumulating value in each group.
    ///
    /// - Parameters:
    ///   - initial: a value to be used as the initial accumulating value in each group.
    ///   - combine: a closure that combines the accumulating value of a group and produces a new accumulating value.
    ///   - groupBy: a closure that produces a key for each element in the sequence.
    /// - Returns: a dictionary containing the final accumulated values for each produced key.
    func groupedReduce<K: Hashable, U>(
        initial: U,
        combine: (U, Iterator.Element) throws -> U,
        groupBy: (Iterator.Element) throws -> K
    ) rethrows -> [K : U] {

        var result: [K : U] = [:]

        for element in self {
            let key = try groupBy(element)
            result[key] = try combine(result[key] ?? initial, element)
        }

        return result
    }

    /// Returns the result of combining the elements of the sequence using the given combining closure, grouped by keys
    /// generated using the a grouping closure. The result is a dictionary of type `[K : U]`. An initial value should
    /// be given to be used as initial accumulating value in each group.
    ///
    /// This method is preferred over `groupedReduce(initial:combine:groupBy:)` for efficiency when the group `U` is a
    /// copy-on-write type, for example an Array or a Dictionary.
    ///
    /// - Parameters:
    ///   - initial: a value to be used as the initial accumulating value in each group.
    ///   - combine: a closure that combines the accumulating value of a group and produces a new accumulating value.
    ///   - groupBy: a closure that produces a key for each element in the sequence.
    /// - Returns: a dictionary containing the final accumulated values for each produced key.
    func groupedReduce<K: Hashable, U>(
        into initial: U,
        combine: (inout U, Iterator.Element) throws -> Void,
        groupBy: (Iterator.Element) throws -> K
    ) rethrows -> [K : U] {

        var result: [K : U] = [:]

        for element in self {
            let key = try groupBy(element)
            var group = result[key] ?? initial
            try combine(&group, element)
            result[key] = group
        }

        return result
    }
}
