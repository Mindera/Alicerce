import XCTest
@testable import Alicerce

class Route_TrieNode_IsEmptyAndDescriptionTests: XCTestCase {

    typealias TrieNode = Route.TrieNode<String>

    // MARK: isEmpty

    func testIsEmpty_withEmptyNode_ShouldReturnTrue() {

        XCTAssertTrue(TrieNode().isEmpty)
    }

    func testIsEmpty_withNonEmptyNode_ShouldReturnFalse() {

        XCTAssertFalse(TrieNode(constants: ["a": TrieNode(handler: "🏗")]).isEmpty)
        XCTAssertFalse(TrieNode(parameter: .init(name: "a", node: TrieNode(handler: "🏗"))).isEmpty)
        XCTAssertFalse(TrieNode(wildcard: TrieNode(handler: "🏗")).isEmpty)
        XCTAssertFalse(TrieNode(catchAll: .init(name: "a", handler: "🏗")).isEmpty)
        XCTAssertFalse(TrieNode(handler: "🏗").isEmpty)
    }

    // MARK: description

    func testDescription_ShouldMatchValue() {

        let node = TrieNode()

        do {
            try node.add(["some", "path"], handler: "handlerA")
            try node.add(["some", "path", "**"], handler: "handlerB")
            try node.add(["some", "path", "*", ":parameterA"], handler: "handlerC")

            try node.add(["another", "path"], handler: "handlerD")
            try node.add(["another", ":parameterA", ":parameterB"], handler: "handlerE")
            try node.add(["another", ":parameterA", ":parameterB", "**parameterC"], handler: "handlerF")

            try node.add([":parameterA", "before", "path"], handler: "handlerG")
            try node.add([":parameterA", ":parameterB", "path", "*"], handler: "handlerH")
            try node.add([":parameterA", ":parameterB", "**"], handler: "handlerI")
            try node.add([":parameterA", "*", "path", "*"], handler: "handlerJ")

            try node.add(["*", "yet", "another", "path"], handler: "handlerK")
            try node.add(["*", "yet", "another", ":parameterA", "*"], handler: "handlerL")
            try node.add(["*", "yet", "another", "**"], handler: "handlerM")

            try node.add(["**catchAll"], handler: "handlerN")

            try node.add([], handler: "handlerO")
        } catch {
            return XCTFail("🔥 Failed to add routes with error: \(error)!")
        }

        XCTAssertEqual(
            node.description,
            """
            ├──┬ some
            │  └──┬ path
            │     ├──┬ *
            │     │  └──┬ :parameterA
            │     │     └──● handlerC
            │     │
            │     ├──┬ **
            │     │  └──● handlerB
            │     │
            │     └──● handlerA
            │
            ├──┬ another
            │  ├──┬ path
            │  │  └──● handlerD
            │  │
            │  └──┬ :parameterA
            │     └──┬ :parameterB
            │        ├──┬ **parameterC
            │        │  └──● handlerF
            │        │
            │        └──● handlerE
            │
            ├──┬ :parameterA
            │  ├──┬ before
            │  │  └──┬ path
            │  │     └──● handlerG
            │  │
            │  ├──┬ :parameterB
            │  │  ├──┬ path
            │  │  │  └──┬ *
            │  │  │     └──● handlerH
            │  │  │
            │  │  └──┬ **
            │  │     └──● handlerI
            │  │
            │  └──┬ *
            │     └──┬ path
            │        └──┬ *
            │           └──● handlerJ
            │
            ├──┬ *
            │  └──┬ yet
            │     └──┬ another
            │        ├──┬ path
            │        │  └──● handlerK
            │        │
            │        ├──┬ :parameterA
            │        │  └──┬ *
            │        │     └──● handlerL
            │        │
            │        └──┬ **
            │           └──● handlerM
            │
            ├──┬ **catchAll
            │  └──● handlerN
            │
            └──● handlerO
            """
        )
    }
}
