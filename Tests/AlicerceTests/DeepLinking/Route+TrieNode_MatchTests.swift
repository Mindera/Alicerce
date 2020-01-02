import XCTest
@testable import Alicerce

class Route_TrieNode_MatchTests: XCTestCase {

    typealias TrieNode = Route.TrieNode<String>

    // MARK: - failure

    // MARK: empty

    func testMatch_WithEmptyRouteOnEmptyNode_ShouldReturnNil() {

        XCTAssertMatchFails(initial: .empty, matchRoute: [])
    }

    // MARK: single component

    func testMatch_WithSingleComponentOnEmptyNode_ShouldReturnNil() {

        XCTAssertMatchFails(initial: .empty, matchRoute: ["a"])
        XCTAssertMatchFails(initial: .empty, matchRoute: [":a"])
        XCTAssertMatchFails(initial: .empty, matchRoute: ["*"])
        XCTAssertMatchFails(initial: .empty, matchRoute: ["**a"])
        XCTAssertMatchFails(initial: .empty, matchRoute: ["**"])
    }

    func testMatch_WithNonMatchingConstantComponent_ShouldReturnNil() {

        XCTAssertMatchFails(initial: .constant("💣", node: .handler("💥")), matchRoute: ["a"])
    }

    // MARK: - success

    // MARK: empty

    func testMatch_WithEmptyRouteOnHandlerNode_ShouldReturnHandler() {

        XCTAssertMatchSucceeeds(initial: .handler("🎉"), matchRoute: [], expectedHandler: "🎉")
    }

    // MARK: single component

    func testMatch_WithSingleComponentRouteOnMatchingNode_ShouldReturnHandler() {

        XCTAssertMatchSucceeeds(
            initial: .constant("👷‍♂️", node: .handler("🎉")),
            matchRoute: ["👷‍♂️"],
            expectedHandler: "🎉"
        )
        XCTAssertMatchSucceeeds(
            initial: .parameter("👷‍♂️", node: .handler("🎉")),
            matchRoute: ["🏗"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗"]
        )
        XCTAssertMatchSucceeeds(initial: .wildcard(.handler("🎉")), matchRoute: ["🏗"], expectedHandler: "🎉")
        XCTAssertMatchSucceeeds(
            initial: .catchAll("👷‍♂️", handler: "🎉"),
            matchRoute: ["🏗"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗"]
        )
        XCTAssertMatchSucceeeds(
            initial: .catchAll(nil, handler: "🎉"),
            matchRoute: ["🏗"],
            expectedHandler: "🎉"
        )
    }

    // MARK: multi component

    func testMatch_WithMultiComponentRouteOnMatchingNode_ShouldReturnHandler() {

        XCTAssertMatchSucceeeds(
            initial: .constant("👷‍♂️", node: .constant("👷‍♀️", node: .handler("🎉"))),
            matchRoute: ["👷‍♂️", "👷‍♀️"],
            expectedHandler: "🎉"
        )
        XCTAssertMatchSucceeeds(
            initial: .constant("👷‍♂️", node: .parameter("👷‍♀️", node: .handler("🎉"))),
            matchRoute: ["👷‍♂️", "🏗"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♀️": "🏗"]
        )
        XCTAssertMatchSucceeeds(
            initial: .constant("👷‍♂️", node: .wildcard(.handler("🎉"))),
            matchRoute: ["👷‍♂️", "🏗"],
            expectedHandler: "🎉"
        )
        XCTAssertMatchSucceeeds(
            initial: .constant("👷‍♂️", node: .catchAll("👷‍♀️", handler: "🎉")),
            matchRoute: ["👷‍♂️", "🏗", "🚧"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♀️": "🏗/🚧"]
        )
        XCTAssertMatchSucceeeds(
            initial: .constant("👷‍♂️", node: .catchAll(nil, handler: "🎉")),
            matchRoute: ["👷‍♂️", "🏗", "🚧"],
            expectedHandler: "🎉"
        )

        XCTAssertMatchSucceeeds(
            initial: .parameter("👷‍♂️", node: .constant("👷‍♀️", node: .handler("🎉"))),
            matchRoute: ["🏗", "👷‍♀️"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗"]
        )
        XCTAssertMatchSucceeeds(
            initial: .parameter("👷‍♂️", node: .parameter("👷‍♀️", node: .handler("🎉"))),
            matchRoute: ["🏗", "🚧"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗", "👷‍♀️": "🚧"]
        )
        XCTAssertMatchSucceeeds(
            initial: .parameter("👷‍♂️", node: .wildcard(.handler("🎉"))),
            matchRoute: ["🏗", "👷‍♀️"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗"]
        )
        XCTAssertMatchSucceeeds(
            initial: .parameter("👷‍♂️", node: .catchAll("👷‍♀️", handler: "🎉")),
            matchRoute: ["🏗", "🚧", "🏢"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗", "👷‍♀️": "🚧/🏢"]
        )
        XCTAssertMatchSucceeeds(
            initial: .parameter("👷‍♂️", node: .catchAll(nil, handler: "🎉")),
            matchRoute: ["🏗", "🚧", "🏢"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗"]
        )

        XCTAssertMatchSucceeeds(
            initial: .wildcard(.constant("👷‍♂️", node: .handler("🎉"))),
            matchRoute: ["🏗", "👷‍♂️"],
            expectedHandler: "🎉"
        )
        XCTAssertMatchSucceeeds(
            initial: .wildcard(.parameter("👷‍♂️", node: .handler("🎉"))),
            matchRoute: ["🏗", "🚧"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🚧"]
        )
        XCTAssertMatchSucceeeds(
            initial: .wildcard(.wildcard(.handler("🎉"))),
            matchRoute: ["🏗", "🚧"],
            expectedHandler: "🎉"
        )
        XCTAssertMatchSucceeeds(
            initial: .wildcard(.catchAll("👷‍♂️", handler: "🎉")),
            matchRoute: ["🏗", "🚧", "👷‍♀️"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🚧/👷‍♀️"]
        )
        XCTAssertMatchSucceeeds(
            initial: .wildcard(.catchAll(nil, handler: "🎉")),
            matchRoute: ["🏗", "🚧", "👷‍♀️"],
            expectedHandler: "🎉"
        )
    }

    // MARK: priority

    func testMatch_WithRouteMatchingMultipleRoutesInNode_ShouldReturnMostPrioritaryHandler() {

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: ["👷‍♂️": .handler("🎉")],
                parameter: .init(name: "👷‍♀️", node: .handler("💥")),
                wildcard: .handler("💣"),
                catchAll: .init(name: "🚧", handler: "🧨"),
                handler: "🕳"
            ),
            matchRoute: ["👷‍♂️"],
            expectedHandler: "🎉"
        )

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: ["👷‍♀️": .handler("💥")],
                parameter: .init(name: "👷‍♀️", node: .handler("🎉")),
                wildcard: .handler("💣"),
                catchAll: .init(name: "🚧", handler: "🧨"),
                handler: "🕳"
            ),
            matchRoute: ["🏗"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♀️": "🏗"]
        )

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: ["👷‍♀️": .handler("💥")],
                wildcard: .handler("🎉"),
                catchAll: .init(name: "🚧", handler: "🧨"),
                handler: "🕳"
            ),
            matchRoute: ["🏗"],
            expectedHandler: "🎉"
        )

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: ["👷‍♀️": .handler("💥")],
                catchAll: .init(name: "🚧", handler: "🎉"),
                handler: "🕳"
            ),
            matchRoute: ["🏗"],
            expectedHandler: "🎉",
            expectedParameters: ["🚧": "🏗"]
        )

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: ["👷‍♀️": .handler("💥")],
                catchAll: .init(name: nil, handler: "🎉"),
                handler: "🕳"
            ),
            matchRoute: ["🏗"],
            expectedHandler: "🎉"
        )
    }

    // MARK: backtracking

    func testMatch_WithRoutePartiallyMatchingMorePrioritaryRoute_ShouldBacktrackAndReturnNextMostPrioritaryHandler() {

        // match: 🏗/🚧
        //
        // ├──┬ 🏗
        // │  └──● 💥
        // │
        // └──┬ :👷‍♂️
        //    └──┬ :👷‍♀️
        //       └──● 🎉

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: ["🏗": .handler("💥")],
                parameter: .init(name: "👷‍♂️", node: .parameter("👷‍♀️", node: .handler("🎉")))
            ),
            matchRoute: ["🏗", "🚧"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗", "👷‍♀️": "🚧"]
        )

        // match: 🏗/🚧/🛠
        //
        // ├──┬ 🏗
        // │  ├──┬ 🚧
        // │  │  └──● 💣
        // │  │
        // │  └──┬ :🔨
        // │     └──┬ 🔧
        // │        └──● 💥
        // │
        // └──┬ :👷‍♂️
        //    └──┬ :👷‍♀️
        //       └──┬ :🏢
        //          └──● 🎉

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: [
                    "🏗": .init(
                        constants: ["🚧": .handler("💣")],
                        parameter: .init(
                            name: "🔨",
                            node: .constant("🔧", node: .handler("💥"))
                        )
                    )
                ],
                parameter: .init(name: "👷‍♂️", node: .parameter("👷‍♀️", node: .parameter("🏢", node: .handler("🎉"))))
            ),
            matchRoute: ["🏗", "🚧", "🛠"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗", "👷‍♀️": "🚧", "🏢": "🛠"]
        )

        // match: 🏗/🚧
        //
        // ├──┬ 🏗
        // │  └──┬ 🚧
        // │     └──┬ :🛠
        // │        └──● 💥
        // │
        // └──┬ :👷‍♂️
        //    └──┬ :👷‍♀️
        //       └──● 🎉

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: ["🏗": .constant("🚧", node: .parameter("🛠", node: .handler("💥")))],
                parameter: .init(name: "👷‍♂️", node: .parameter("👷‍♀️", node: .handler("🎉")))
            ),
            matchRoute: ["🏗", "🚧"],
            expectedHandler: "🎉",
            expectedParameters: ["👷‍♂️": "🏗", "👷‍♀️": "🚧"]
        )

        // match 🏗/🚧/🛠/🏢
        //
        // ├──┬ 🏗
        // │  └──┬ 🚧
        // │     └──┬ :🛠
        // │        └──● 💥
        // │
        // ├──┬ :👷‍♂️
        // │  └──┬ :👷‍♀️
        // │     └──┬ :🤷‍♂️
        // │        └──● 💣
        // │
        // ├──┬ *
        // │  └──┬ :🚧
        // │     └──┬ 🛠
        // │        └──┬ 🏠
        // │           └──● 🧨
        // │
        // └──┬ **🕳
        //    └──● 🎉

        XCTAssertMatchSucceeeds(
            initial: .init(
                constants: ["🏗": .constant("🚧", node: .parameter("🛠", node: .handler("💥")))],
                parameter: .init(name: "👷‍♂️", node: .parameter("👷‍♀️", node: .parameter("🤷‍♂️", node: .handler("💣")))),
                wildcard: .parameter("🚧", node: .constant("🛠", node: .constant("🏠", node: .handler("🧨")))),
                catchAll: .init(name: "🕳", handler: "🎉")
            ),
            matchRoute: ["🏗", "🚧", "🛠", "🏢"],
            expectedHandler: "🎉",
            expectedParameters: ["🕳": "🏗/🚧/🛠/🏢"]
        )
    }
}

private extension Route_TrieNode_MatchTests {

    private func XCTAssertMatchFails(
        initial node: TrieNode,
        matchRoute: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {

        var parameters = [String: String]()

        XCTAssertNil(node.match(matchRoute, parameters: &parameters), file: file, line: line)
        XCTAssertEqual(parameters, [:], file: file, line: line)
    }

    private func XCTAssertMatchSucceeeds(
        initial node: TrieNode,
        matchRoute: [String],
        expectedHandler: String,
        expectedParameters: [String: String] = [:],
        file: StaticString = #file,
        line: UInt = #line
    ) {

        var parameters = [String: String]()

        XCTAssertEqual(node.match(matchRoute, parameters: &parameters), expectedHandler, file: file, line: line)
        XCTAssertEqual(parameters, expectedParameters, file: file, line: line)
    }
}
