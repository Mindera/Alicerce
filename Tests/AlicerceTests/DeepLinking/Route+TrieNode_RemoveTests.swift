import XCTest
@testable import Alicerce

class Route_TrieNode_RemoveTests: XCTestCase {

    typealias TrieNode = Route.TrieNode<String>

    // MARK: - failure

    func testRemove_WithEmptyRouteOnNodeWithoutNodeHandler_ShouldFail() {

        XCTAssertRemoveThrowsRouteNotFound(initial: .empty, removeRoute: [])
        XCTAssertRemoveThrowsRouteNotFound(initial: .constant("a", node: .handler("💥")), removeRoute: [])
        XCTAssertRemoveThrowsRouteNotFound(initial: .parameter("a", node: .handler("💥")), removeRoute: [])
        XCTAssertRemoveThrowsRouteNotFound(initial: .wildcard(.handler("💥")), removeRoute: [])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll("a", handler: "💥"), removeRoute: [])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll(nil, handler: "💥"), removeRoute: [])
    }

    func testRemove_WithNonMatchingConstantComponent_ShouldFail() {

        XCTAssertRemoveThrowsRouteNotFound(initial: .empty, removeRoute: ["💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .constant("a", node: .handler("💥")), removeRoute: ["💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .parameter("a", node: .handler("💥")), removeRoute: ["💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .wildcard(.handler("💥")), removeRoute: ["💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll("a", handler: "💥"), removeRoute: ["💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll(nil, handler: "💥"), removeRoute: ["💣"])
    }

    func testRemove_WithNonMatchingParameterComponent_ShouldFail() {

        XCTAssertRemoveThrowsRouteNotFound(initial: .empty, removeRoute: [":💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .constant("a", node: .handler("💥")), removeRoute: [":💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .parameter("a", node: .handler("💥")), removeRoute: [":💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .wildcard(.handler("💥")), removeRoute: [":💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll("a", handler: "💥"), removeRoute: [":💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll(nil, handler: "💥"), removeRoute: [":💣"])
    }

    func testRemove_WithNonMatchingWildcardComponent_ShouldFail() {

        XCTAssertRemoveThrowsRouteNotFound(initial: .empty, removeRoute: ["*"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .constant("a", node: .handler("💥")), removeRoute: ["*"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .parameter("a", node: .handler("💥")), removeRoute: ["*"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll("a", handler: "💥"), removeRoute: ["*"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll(nil, handler: "💥"), removeRoute: ["*"])
    }

    func testRemove_WithNonMatchingCatchAllComponent_ShouldFail() {

        XCTAssertRemoveThrowsRouteNotFound(initial: .empty, removeRoute: ["**💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .constant("a", node: .handler("💥")), removeRoute: ["**💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .parameter("a", node: .handler("💥")), removeRoute: ["**💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .wildcard(.handler("💥")), removeRoute: ["**💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll("a", handler: "💥"), removeRoute: ["**💣"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll(nil, handler: "💥"), removeRoute: ["**💣"])

        XCTAssertRemoveThrowsRouteNotFound(initial: .empty, removeRoute: ["**"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .constant("a", node: .handler("💥")), removeRoute: ["**"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .parameter("a", node: .handler("💥")), removeRoute: ["**"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .wildcard(.handler("💥")), removeRoute: ["**"])
        XCTAssertRemoveThrowsRouteNotFound(initial: .catchAll("a", handler: "💥"), removeRoute: ["**"])
    }

    func testAdd_WithMisplacedCatchAllComponent_ShouldFail() {

        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .empty,
            removeRoute: ["**💣", "😱"],
            catchAllName: "💣"
        )
        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .constant("a", node: .handler("💥")),
            removeRoute: ["**💣", "😱"],
            catchAllName: "💣"
        )
        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .parameter("a", node: .handler("💥")),
            removeRoute: ["**💣", "😱"],
            catchAllName: "💣"
        )
        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .catchAll("a", handler: "💥"),
            removeRoute: ["**💣", "😱"],
            catchAllName: "💣"
        )
        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .catchAll(nil, handler: "💥"),
            removeRoute: ["**💣", "😱"],
            catchAllName: "💣"
        )

        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .empty,
            removeRoute: ["**", "😱"],
            catchAllName: nil
        )
        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .constant("a", node: .handler("💥")),
            removeRoute: ["**", "😱"],
            catchAllName: nil
        )
        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .parameter("a", node: .handler("💥")),
            removeRoute: ["**", "😱"],
            catchAllName: nil
        )
        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .catchAll("a", handler: "💥"),
            removeRoute: ["**", "😱"],
            catchAllName: nil
        )
        XCTAssertRemoveThrowsMisplacedCatchAllComponent(
            initial: .catchAll(nil, handler: "💥"),
            removeRoute: ["**", "😱"],
            catchAllName: nil
        )
    }

    // MARK: - success

    // MARK: single component

    func testRemove_WithEmptyRouteOnHandlerNode_ShouldSucceed() {

        XCTAssertRemoveSucceeds(initial: .handler("🎉"), removeRoute: [], expected: .empty, expectedHandler: "🎉")
    }

    func testRemove_WithMatchingSingleComponent_ShouldSucceed() {

        XCTAssertRemoveSucceeds(
            initial: .constant("🏗", node: .handler("🎉")),
            removeRoute: ["🏗"],
            expected: .empty,
            expectedHandler: "🎉"
        )
        XCTAssertRemoveSucceeds(
            initial: .constants(["🏗": .handler("🎉"), "👷‍♂️": .handler("🛠")]),
            removeRoute: ["🏗"],
            expected: .constant("👷‍♂️", node: .handler("🛠")),
            expectedHandler: "🎉"
        )

        XCTAssertRemoveSucceeds(
            initial: .parameter("🏗", node: .handler("🎉")),
            removeRoute: [":🏗"],
            expected: .empty,
            expectedHandler: "🎉"
        )

        XCTAssertRemoveSucceeds(
            initial: .wildcard(.handler("🎉")),
            removeRoute: ["*"],
            expected: .empty,
            expectedHandler: "🎉"
        )

        XCTAssertRemoveSucceeds(
            initial: .catchAll("🏗", handler: "🎉"),
            removeRoute: ["**🏗"],
            expected: .empty,
            expectedHandler: "🎉"
        )
        XCTAssertRemoveSucceeds(
            initial: .catchAll(nil, handler: "🎉"),
            removeRoute: ["**"],
            expected: .empty,
            expectedHandler: "🎉"
        )
    }

    // MARK: multi component

    func testRemove_WithMatchingMultiComponent_ShouldSucceed() {

        XCTAssertRemoveSucceeds(
            initial: .constant("🏗", node: .constant("👷‍♂️", node: .handler("🎉"))),
            removeRoute: ["🏗", "👷‍♂️"],
            expected: .empty,
            expectedHandler: "🎉"
        )
        XCTAssertRemoveSucceeds(
            initial: .constant("🏗", node: .constants(["👷‍♂️": .handler("🎉"), "👷‍♀️": .handler("🛠")])),
            removeRoute: ["🏗", "👷‍♂️"],
            expected: .constant("🏗", node: .constant("👷‍♀️", node: .handler("🛠"))),
            expectedHandler: "🎉"
        )

        XCTAssertRemoveSucceeds(
            initial: .parameter("🏗", node: .constant("👷‍♂️", node: .handler("🎉"))),
            removeRoute: [":🏗", "👷‍♂️"],
            expected: .empty,
            expectedHandler: "🎉"
        )
        XCTAssertRemoveSucceeds(
            initial: .parameter("🏗", node: .constants(["👷‍♂️": .handler("🎉"), "👷‍♀️": .handler("🛠")])),
            removeRoute: [":🏗", "👷‍♂️"],
            expected: .parameter("🏗", node: .constant("👷‍♀️", node: .handler("🛠"))),
            expectedHandler: "🎉"
        )

        XCTAssertRemoveSucceeds(
            initial: .wildcard(.constant("👷‍♂️", node: .handler("🎉"))),
            removeRoute: ["*", "👷‍♂️"],
            expected: .empty,
            expectedHandler: "🎉"
        )
        XCTAssertRemoveSucceeds(
            initial: .wildcard(.constants(["👷‍♂️": .handler("🎉"), "👷‍♀️": .handler("🛠")])),
            removeRoute: ["*", "👷‍♂️"],
            expected: .wildcard(.constant("👷‍♀️", node: .handler("🛠"))),
            expectedHandler: "🎉"
        )
    }
}

// MARK: - helpers

private extension Route_TrieNode_RemoveTests {

    func XCTAssertRemoveThrowsRouteNotFound(
        initial: @autoclosure () -> TrieNode,
        removeRoute: [Route.Component],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let node = initial()

        XCTAssertThrowsError(try node.remove(removeRoute), "🔥 Unexpected success!", file: file, line: line) {
            guard case Route.TrieNodeError.routeNotFound = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
        XCTAssertEqual(node, initial(), file: file, line: line)
    }

    func XCTAssertRemoveThrowsMisplacedCatchAllComponent(
        initial: @autoclosure () -> TrieNode,
        removeRoute: [Route.Component],
        catchAllName: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let node = initial()

        XCTAssertTrue(removeRoute.contains(.catchAll(catchAllName)), file: file, line: line)
        XCTAssertThrowsError(try node.remove(removeRoute), "🔥 Unexpected success!", file: file, line: line) {
            guard case Route.TrieNodeError.misplacedCatchAllComponent(catchAllName) = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
        XCTAssertEqual(node, initial(), file: file, line: line)
    }

    func XCTAssertRemoveSucceeds(
        initial node: TrieNode,
        removeRoute: [Route.Component],
        expected: TrieNode,
        expectedHandler: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        XCTAssertEqual(try node.remove(removeRoute), expectedHandler, file: file, line: line)
        XCTAssertEqual(node, expected, file: file, line: line)
    }
}
