import XCTest
@testable import Alicerce

class Route_TrieNode_InitTests: XCTestCase {

    typealias TrieNode = Route.TrieNode<String>

    let testHandler = "test"

    // MARK: failure

    func testInit_WithRouteWithComponentAfterCatchAllElement_ShouldFail() {

        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: "catchAll", secondComponent: .constant("a"))
        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: nil, secondComponent: .constant("a"))

        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: "catchAll", secondComponent: .parameter("a"))
        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: nil, secondComponent: .parameter("a"))

        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: "catchAll", secondComponent: .wildcard)
        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: nil, secondComponent: .wildcard)

        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: "catchAll", secondComponent: .catchAll("a"))
        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: nil, secondComponent: .catchAll("a"))
        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: "catchAll", secondComponent: .catchAll(nil))
        XCTAssertThrowsMisplacedCatchAllComponent(catchAllName: nil, secondComponent: .catchAll(nil))
    }

    func testInit_WithRouteWithDuplicateParameterName_ShouldFail() {

        XCTAssertThrowsDuplicateParameterName(initRoute: [":a", ":a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(initRoute: [":a", "b", ":a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(initRoute: [":a", ":b", ":a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(initRoute: [":a", ":b", "*", ":c", ":a"], duplicateParameterName: "a")

        XCTAssertThrowsDuplicateParameterName(initRoute: [":a", "**a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(initRoute: [":a", "b", "**a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(initRoute: [":a", ":b", "**a"], duplicateParameterName: "a")
        XCTAssertThrowsDuplicateParameterName(initRoute: [":a", ":b", "*", ":c", "**a"], duplicateParameterName: "a")
    }

    // MARK: success

    // MARK: single level node

    func testInit_WithEmptyRoute_ShouldCreateNodeWithHandler() {

        XCTAssertEqual(try TrieNode(route: [], handler: testHandler), .handler(testHandler))
    }

    func testInit_WithSingleComponentRoute_ShouldCreateNodeWithCorrectChild() {

        XCTAssertEqual(
            try TrieNode(route: [.constant("a")], handler: testHandler),
            .constant("a", node: TrieNode(handler: testHandler))
        )

        XCTAssertEqual(
            try TrieNode(route: [.parameter("a")], handler: testHandler),
            .parameter("a", node: TrieNode(handler: testHandler))
        )

        XCTAssertEqual(
            try TrieNode(route: [.wildcard], handler: testHandler),
            .wildcard(TrieNode(handler: testHandler))
        )

        XCTAssertEqual(
            try TrieNode(route: [.catchAll("a")], handler: testHandler),
            .catchAll("a", handler: testHandler)
        )

        XCTAssertEqual(
            try TrieNode(route: [.catchAll(nil)], handler: testHandler),
            .catchAll(nil, handler: testHandler)
        )
    }

    // MARK: multi level node

    func testInit_WithMultiComponentRoute_ShouldCreateNodeWithCorrectChildren() {

        XCTAssertEqual(
            try TrieNode(route: ["a", "b", "c"], handler: testHandler),
            .constant("a", node:
                .constant("b", node:
                    .constant("c", node: TrieNode(handler: testHandler))
                )
            )
        )

        XCTAssertEqual(
            try TrieNode(route: [":a", ":b", ":c"], handler: testHandler),
            .parameter("a", node:
                .parameter("b", node:
                    .parameter("c", node: TrieNode(handler: testHandler))
                )
            )
        )

        XCTAssertEqual(
            try TrieNode(route: ["a", ":b", "*", "**d"], handler: testHandler),
            .constant("a", node:
                .parameter("b", node:
                    .wildcard(
                        .catchAll("d", handler: testHandler)
                    )
                )
            )
        )
    }
}

// MARK: - helpers

private extension Route_TrieNode_InitTests {

    func XCTAssertThrowsMisplacedCatchAllComponent(
        catchAllName: String?,
        secondComponent: Route.Component,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(
            try TrieNode(route: [.catchAll(catchAllName), secondComponent], handler: testHandler),
            "🔥 unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.TrieNodeError.misplacedCatchAllComponent(catchAllName) = $0 else {
                XCTFail("🔥 Unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }

    func XCTAssertThrowsDuplicateParameterName(
        initRoute: [Route.Component],
        duplicateParameterName: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        XCTAssertThrowsError(
            try TrieNode(route: initRoute, handler: testHandler),
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
}
