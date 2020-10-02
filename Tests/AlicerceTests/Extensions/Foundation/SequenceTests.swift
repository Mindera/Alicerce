import XCTest
@testable import Alicerce

class SequenceTests: XCTestCase {

    // MARK: groupedReduce

    func testGroupedReduce_WithNonEmptySequenceAndSameKeyType_ShouldReturnGroupedDictionary() {

        let seq = ["a", "a", "a", "b", "b", "c", "d"]

        let sumCombine: (Int, String) -> Int = { acc, element in return acc + 1 }
        let stringKey: (String) -> String = { $0 }

        let groupedSeq: [String : Int] = seq.groupedReduce(initial: 0, combine: sumCombine, groupBy: stringKey)

        XCTAssertEqual(groupedSeq, ["a" : 3, "b" : 2, "c" : 1, "d" : 1])
    }

    func testGroupedReduce_WithEmptySequence_ShouldReturnEmptyDictionary() {

        let seq: [String] = []

        let sumCombine: (Int, String) -> Int = { acc, element in return acc + 1 }
        let stringKey: (String) -> String = { $0 }

        let groupedSeq: [String : Int] = seq.groupedReduce(initial: 0, combine: sumCombine, groupBy: stringKey)

        XCTAssertEqual(groupedSeq, [:])
    }

    func testGroupedReduce_WithNonEmptySequenceAndDifferentKeyType_ShouldReturnGroupedDictionary() {

        let seq = ["a", "a", "a", "b", "b", "c", "d"]

        let sumCombine: (Int, String) -> Int = { acc, element in return acc + 1 }
        let utf8Key: (String) -> UTF8Char = { $0.utf8.first! }

        let groupedSeq: [UTF8Char : Int] = seq.groupedReduce(initial: 0, combine: sumCombine, groupBy: utf8Key)

        XCTAssertEqual(groupedSeq, ["a".utf8.first! : 3, "b".utf8.first! : 2, "c".utf8.first! : 1, "d".utf8.first! : 1])
    }

    func testGroupedReduceInto_WithNonEmptySequenceAndSameKeyType_ShouldReturnGroupedDictionary() {

        let seq = ["a", "a", "a", "b", "b", "c", "d"]

        let sumCombine: (inout Int, String) -> Void = { acc, element in acc += 1 }
        let stringKey: (String) -> String = { $0 }

        let groupedSeq: [String : Int] = seq.groupedReduce(into: 0, combine: sumCombine, groupBy: stringKey)

        XCTAssertEqual(groupedSeq, ["a" : 3, "b" : 2, "c" : 1, "d" : 1])
    }

    func testGroupedReduceInto_WithEmptySequence_ShouldReturnEmptyDictionary() {

        let seq: [String] = []

        let sumCombine: (inout Int, String) -> Void = { acc, element in acc += 1 }
        let stringKey: (String) -> String = { $0 }

        let groupedSeq: [String : Int] = seq.groupedReduce(into: 0, combine: sumCombine, groupBy: stringKey)

        XCTAssertEqual(groupedSeq, [:])
    }

    func testGroupedReduceInto_WithNonEmptySequenceAndDifferentKeyType_ShouldReturnGroupedDictionary() {

        let seq = ["a", "a", "a", "b", "b", "c", "d"]

        let sumCombine: (inout Int, String) -> Void = { acc, element in acc += 1 }
        let utf8Key: (String) -> UTF8Char = { $0.utf8.first! }

        let groupedSeq: [UTF8Char : Int] = seq.groupedReduce(into: 0, combine: sumCombine, groupBy: utf8Key)

        XCTAssertEqual(groupedSeq, ["a".utf8.first! : 3, "b".utf8.first! : 2, "c".utf8.first! : 1, "d".utf8.first! : 1])
    }
}
