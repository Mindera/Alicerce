import XCTest
@testable import Alicerce

class Route_TrieNode_AddTests: XCTestCase {
    
    typealias TrieNode = Route.TrieNode<String>

    // MARK: - failure

    func testAdd_WithConflictingHandlerNodeOnAlreadyExistingHandlerNode_ShouldFail() {

        let node = TrieNode(handler: "💣")

        XCTAssertThrowsError(try node.add([], handler: "💥"), "🔥 Unexpected success!") {
            guard case Route.TrieNodeError.conflictingNodeHandler = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }
        XCTAssertEqual(node, .handler("💣"))
    }

    func testAdd_WithMisplacedCatchAllComponent_ShouldFail() {

        XCTAssertAddThrowsMisplacedCatchAllComponent(addRoute: ["a", "**💣", "😱"], catchAllName: "💣")
        XCTAssertAddThrowsMisplacedCatchAllComponent(addRoute: [":a", "**💣", "😱"], catchAllName: "💣")
        XCTAssertAddThrowsMisplacedCatchAllComponent(addRoute: ["*", "**💣", "😱"], catchAllName: "💣")
        XCTAssertAddThrowsMisplacedCatchAllComponent(addRoute: ["**💣", "😱"], catchAllName: "💣")

        XCTAssertAddThrowsMisplacedCatchAllComponent(addRoute: ["a", "**", "😱"], catchAllName: nil)
        XCTAssertAddThrowsMisplacedCatchAllComponent(addRoute: [":a", "**", "😱"], catchAllName: nil)
        XCTAssertAddThrowsMisplacedCatchAllComponent(addRoute: ["*", "**", "😱"], catchAllName: nil)
        XCTAssertAddThrowsMisplacedCatchAllComponent(addRoute: ["**", "😱"], catchAllName: nil)
    }

    func testAdd_WithConflictingParameterName_ShouldFail() {

        let node = TrieNode.parameter("💣", node: .handler("💥"))

        XCTAssertThrowsError(try node.add([":🧨", "😱"], handler: "💥"), "🔥 Unexpected success!") {
            guard case Route.TrieNodeError.conflictingParameterName(existing: "💣", new: "🧨") = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }
        XCTAssertEqual(node, .parameter("💣", node: .handler("💥")))
    }

    func testAdd_WithConflictingCatchAllName_ShouldFail() {

        XCTAssertAddThrowsConflictingCatchAllComponent(existingCatchAllName: "💣", newCatchAllName: "🧨")
        XCTAssertAddThrowsConflictingCatchAllComponent(existingCatchAllName: "💣", newCatchAllName: nil)
        XCTAssertAddThrowsConflictingCatchAllComponent(existingCatchAllName: nil, newCatchAllName: "🧨")
        XCTAssertAddThrowsConflictingCatchAllComponent(existingCatchAllName: nil, newCatchAllName: nil)
    }

    func testAdd_WithDuplicateParameterName_ShouldFail() {

        XCTAssertThrowsDuplicateParameterName(addRoute: [":a", ":a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(addRoute: [":a", "b", ":a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(addRoute: [":a", ":b", ":a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(addRoute: [":a", ":b", "*", ":a"], duplicateParameterName: "a")

        XCTAssertThrowsDuplicateParameterName(addRoute: [":a", "**a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(addRoute: [":a", "b", "**a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(addRoute: [":a", ":b", "**a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(addRoute: [":a", ":b", "*", "**a"], duplicateParameterName: "a")

        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .handler("a")),
            addRoute: [":a", ":a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .constant("b", node: .handler("a"))),
            addRoute: [":a", "b", ":a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .handler("a")),
            addRoute: [":a", "b", ":a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .parameter("b", node: .handler("a"))),
            addRoute: [":a", ":b", ":a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .parameter("b", node: .wildcard(.handler("a")))),
            addRoute: [":a", ":b", "*", ":a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .parameter("b", node: .handler("a"))),
            addRoute: [":a", ":b", "*", ":a"],
            duplicateParameterName: "a"
        )

        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .handler("a")),
            addRoute: [":a", "**a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .constant("b", node: .handler("a"))),
            addRoute: [":a", "b", "**a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .handler("a")),
            addRoute: [":a", "b", "**a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .parameter("b", node: .handler("a"))),
            addRoute: [":a", ":b", "**a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .parameter("b", node: .wildcard(.handler("a")))),
            addRoute: [":a", ":b", "*", "**a"],
            duplicateParameterName: "a"
        )
        XCTAssertThrowsDuplicateParameterName(
            initial: .parameter("a", node: .parameter("b", node: .handler("a"))),
            addRoute: [":a", ":b", "*", "**a"],
            duplicateParameterName: "a"
        )

    }

    // MARK: - success

    // MARK: single component

    func testAdd_WithSingleComponentOnEmptyNode_ShouldSucceed() {

        XCTAssertAddSucceeds(addRoute: ["a"], expected: .constant("a", node: .handler("🎉")))
        XCTAssertAddSucceeds(addRoute: [":a"], expected: .parameter("a", node: TrieNode(handler: "🎉")))
        XCTAssertAddSucceeds(addRoute: ["*"], expected: .wildcard(.handler("🎉")))
        XCTAssertAddSucceeds(addRoute: ["**a"], expected: .catchAll("a", handler: "🎉"))
        XCTAssertAddSucceeds(addRoute: ["**"], expected: .catchAll(nil, handler: "🎉"))
        XCTAssertAddSucceeds(addRoute: [], expected: .handler("🎉"))
    }

    func testAdd_WithSingleComponentOnConstantNode_ShouldSucceed() {

        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["b"],
            expected: .constants(["a": .handler("🏗"), "b": .handler("🎉")])
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: [":b"],
            expected: .init(constants: ["a": .handler("🏗")], parameter: .init(name: "b", node: .handler("🎉")))
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["*"],
            expected: .init(constants: ["a": .handler("🏗")], wildcard: .handler("🎉"))
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["**b"],
            expected: .init(constants: ["a": .handler("🏗")], catchAll: .init(name: "b", handler: "🎉"))
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["**"],
            expected: .init(constants: ["a": .handler("🏗")], catchAll: .init(name: nil, handler: "🎉"))
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: [],
            expected: .init(constants: ["a": .handler("🏗")], handler: "🎉")
        )
    }

    func testAdd_WithSingleComponentOnParameterNode_ShouldSucceed() {

        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: ["b"],
            expected: .init(constants: ["b": .handler("🎉")], parameter: .init(name: "a", node: .handler("🏗")))
        )
        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: ["*"],
            expected: .init(parameter: .init(name: "a", node: .handler("🏗")), wildcard: .handler("🎉"))
        )
        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: ["**b"],
            expected: .init(
                parameter: .init(name: "a", node: .handler("🏗")),
                catchAll: .init(name: "b", handler: "🎉")
            )
        )
        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: ["**"],
            expected: .init(
                parameter: .init(name: "a", node: .handler("🏗")),
                catchAll: .init(name: nil, handler: "🎉")
            )
        )
        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: [],
            expected: .init(parameter: .init(name: "a", node: .handler("🏗")), handler: "🎉")
        )
    }

    func testAdd_WithSingleComponentOnWildcardNode_ShouldSucceed() {

        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: ["b"],
            expected: .init(constants: ["b": .handler("🎉")], wildcard: .handler("🏗"))
        )
        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: [":b"],
            expected: .init(parameter: .init(name: "b", node: .handler("🎉")), wildcard: .handler("🏗"))
        )
        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: ["**b"],
            expected: .init(wildcard: .handler("🏗"), catchAll: .init(name: "b", handler: "🎉"))
        )
        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: ["**"],
            expected: .init(wildcard: .handler("🏗"), catchAll: .init(name: nil, handler: "🎉"))
        )
        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: [],
            expected: .init(wildcard: .handler("🏗"), handler: "🎉")
        )
    }

    func testAdd_WithSingleComponentOnCatchAllNode_ShouldSucceed() {

        XCTAssertAddSucceeds(
            initial: .catchAll("a", handler: "🏗"),
            addRoute: ["b"],
            expected: .init(constants: ["b": .handler("🎉")], catchAll: .init(name: "a", handler: "🏗"))
        )
        XCTAssertAddSucceeds(
            initial: .catchAll("a", handler: "🏗"),
            addRoute: [":b"],
            expected: .init(
                parameter: .init(name: "b", node: .handler("🎉")),
                catchAll: .init(name: "a", handler: "🏗")
            )
        )
        XCTAssertAddSucceeds(
            initial: .catchAll("a", handler: "🏗"),
            addRoute: ["*"],
            expected: .init(wildcard: .handler("🎉"), catchAll: .init(name: "a", handler: "🏗"))
        )
        XCTAssertAddSucceeds(
            initial: .catchAll("a", handler: "🏗"),
            addRoute: [],
            expected: .init(catchAll: .init(name: "a", handler: "🏗"), handler: "🎉")
        )

        XCTAssertAddSucceeds(
            initial: .catchAll(nil, handler: "🏗"),
            addRoute: ["b"],
            expected: .init(constants: ["b": .handler("🎉")], catchAll: .init(name: nil, handler: "🏗"))
        )
        XCTAssertAddSucceeds(
            initial: .catchAll(nil, handler: "🏗"),
            addRoute: [":b"],
            expected: .init(
                parameter: .init(name: "b", node: .handler("🎉")),
                catchAll: .init(name: nil, handler: "🏗")
            )
        )
        XCTAssertAddSucceeds(
            initial: .catchAll(nil, handler: "🏗"),
            addRoute: ["*"],
            expected: .init(wildcard: .handler("🎉"), catchAll: .init(name: nil, handler: "🏗"))
        )
        XCTAssertAddSucceeds(
            initial: .catchAll(nil, handler: "🏗"),
            addRoute: [],
            expected: .init(catchAll: .init(name: nil, handler: "🏗"), handler: "🎉")
        )
    }

    func testAdd_WithSingleComponentOnHandlerNode_ShouldSucceed() {

        XCTAssertAddSucceeds(
            initial: .handler("🏗"),
            addRoute: ["a"],
            expected: .init(constants: ["a": .handler("🎉")], handler: "🏗")
        )
        XCTAssertAddSucceeds(
            initial: .handler("🏗"),
            addRoute: [":a"],
            expected: .init(parameter: .init(name: "a", node: .handler("🎉")), handler: "🏗")
        )
        XCTAssertAddSucceeds(
            initial: .handler("🏗"),
            addRoute: ["*"],
            expected: .init(wildcard: .handler("🎉"), handler: "🏗")
        )
        XCTAssertAddSucceeds(
            initial: .handler("🏗"),
            addRoute: ["**a"],
            expected: .init(catchAll: .init(name: "a", handler: "🎉"), handler: "🏗")
        )
        XCTAssertAddSucceeds(
            initial: .handler("🏗"),
            addRoute: ["**"],
            expected: .init(catchAll: .init(name: nil, handler: "🎉"), handler: "🏗")
        )
    }

    // MARK: multi component

    func testAdd_WithMultiComponentOnMatchingConstantNode_ShouldSucceed() {

        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["a", "b"],
            expected: .init(
                constants: [
                    "a": .init(
                        constants: ["b": .handler("🎉")],
                        handler: "🏗"
                    )
                ]
            )
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["a", ":b"],
            expected: .init(
                constants: [
                    "a": .init(
                        parameter: .init(name: "b", node: .handler("🎉")),
                        handler: "🏗"
                    )
                ]
            )
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["a", "*"],
            expected:.init(
                constants: [
                    "a": .init(
                        wildcard: .handler("🎉"),
                        handler: "🏗"
                    )
                ]
            )
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["a", "**b"],
            expected: .init(
                constants: [
                    "a": .init(
                        catchAll: .init(name: "b", handler: "🎉"),
                        handler: "🏗"
                    )
                ]
            )
        )
        XCTAssertAddSucceeds(
            initial: .constant("a", node: .handler("🏗")),
            addRoute: ["a", "**"],
            expected: .init(
                constants: [
                    "a": .init(
                        catchAll: .init(name: nil, handler: "🎉"),
                        handler: "🏗"
                    )
                ]
            )
        )
    }

    func testAdd_WithMultiComponentOnMatchingParameterNode_ShouldSucceed() {

        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: [":a", "b"],
            expected: .init(
                parameter: .init(
                    name: "a",
                    node: .init(
                        constants: ["b": .handler("🎉")],
                        handler: "🏗"
                    )
                )
            )
        )
        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: [":a", ":b"],
            expected: .init(
                parameter: .init(
                    name: "a",
                    node: .init(
                        parameter: .init(name: "b", node: .handler("🎉")),
                        handler: "🏗"
                    )
                )
            )
        )
        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: [":a", "*"],
            expected: .init(
                parameter: .init(
                    name: "a",
                    node: .init(
                        wildcard: .handler("🎉"),
                        handler: "🏗"
                    )
                )
            )
        )
        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: [":a", "**b"],
            expected: .init(
                parameter: .init(
                    name: "a",
                    node: .init(
                        catchAll: .init(name: "b", handler: "🎉"),
                        handler: "🏗"
                    )
                )
            )
        )
        XCTAssertAddSucceeds(
            initial: .parameter("a", node: .handler("🏗")),
            addRoute: [":a", "**"],
            expected: .init(
                parameter: .init(
                    name: "a",
                    node: .init(
                        catchAll: .init(name: nil, handler: "🎉"),
                        handler: "🏗"
                    )
                )
            )
        )
    }

    func testAdd_WithMultiComponentOnMatchingWildcardNode_ShouldSucceed() {

        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: ["*", "b"],
            expected: .init(
                wildcard: .init(
                    constants: ["b": .handler("🎉")],
                    handler: "🏗"
                )
            )
        )
        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: ["*", ":b"],
            expected: .init(
                wildcard: .init(
                    parameter: .init(name: "b", node: .handler("🎉")),
                    handler: "🏗"
                )
            )
        )
        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: ["*", "*"],
            expected: .init(
                wildcard: .init(
                    wildcard: .handler("🎉"),
                    handler: "🏗"
                )
            )
        )
        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: ["*", "**b"],
            expected: .init(
                wildcard: .init(
                    catchAll: .init(name: "b", handler: "🎉"),
                    handler: "🏗"
                )
            )
        )
        XCTAssertAddSucceeds(
            initial: .wildcard(.handler("🏗")),
            addRoute: ["*", "**"],
            expected: .init(
                wildcard: .init(
                    catchAll: .init(name: nil, handler: "🎉"),
                    handler: "🏗"
                )
            )
        )
    }
}

// MARK: - helpers

private extension Route_TrieNode_AddTests {

    func XCTAssertAddThrowsMisplacedCatchAllComponent(
        addRoute: [Route.Component],
        catchAllName: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let node = TrieNode()

        XCTAssertTrue(addRoute.contains(.catchAll(catchAllName)), file: file, line: line)
        XCTAssertThrowsError(
            try node.add(addRoute, handler: "💥"),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.TrieNodeError.misplacedCatchAllComponent(catchAllName) = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
        XCTAssertEqual(node, .empty, file: file, line: line)
    }

    func XCTAssertAddThrowsConflictingCatchAllComponent(
        existingCatchAllName: String?,
        newCatchAllName: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let node = TrieNode.catchAll(existingCatchAllName, handler: "💣")

        XCTAssertThrowsError(
            try node.add([.catchAll(newCatchAllName)], handler: "💥"),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard
                case Route.TrieNodeError.conflictingCatchAllComponent(existingCatchAllName, newCatchAllName) = $0
            else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
        XCTAssertEqual(node, .catchAll(existingCatchAllName, handler: "💣"), file: file, line: line)
    }

    func XCTAssertThrowsDuplicateParameterName(
        initial node: TrieNode = .empty,
        addRoute: [Route.Component],
        duplicateParameterName: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        XCTAssertThrowsError(
            try node.add(addRoute, handler: "💥"),
            "🔥 unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.TrieNodeError.duplicateParameterName(duplicateParameterName) = $0 else {
                XCTFail("🔥 Unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }

    func XCTAssertAddSucceeds(
        initial node: TrieNode = .empty,
        addRoute: [Route.Component],
        expected: TrieNode,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        XCTAssertNoThrow(try node.add(addRoute, handler: "🎉"), file: file, line: line)
        XCTAssertEqual(node, expected, file: file, line: line)
    }
}
