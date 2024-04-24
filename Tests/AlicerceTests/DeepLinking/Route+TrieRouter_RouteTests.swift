import XCTest
@testable import Alicerce

class Route_TrieRouter_RouteTests: XCTestCase {

    typealias TestRouter = Route.TrieRouter<URL, HandledRoute>
    typealias TestRouteTrieNode = Route.TrieNode<TestHandler>
    typealias AnyTestHandler = AnyRouteHandler<URL, HandledRoute>

    var testHandler = AnyTestHandler(TestHandler())

    // MARK: - failure

    func testRoute_WithInvalidRouteURL_ShouldFail() {
        guard #unavailable(iOS 17, macOS 14) else {
            // Since iOS 17, macOS 14 that both `URL` and `URLComponents` conform to RFC 3986, so we can't create a
            // `URL` that would fail to create a `URLComponents` (triggering the `.invalidRoute(.invalidURL)` error).
            // https://stackoverflow.com/a/55627352/1921751
            return
        }

        let router = TestRouter()

        XCTAssertThrowsError(
            try router.route("scheme://:parameter/path".url()),
            "🔥 Unexpected success!") {
            guard case Route.TrieRouterError.invalidRoute(.invalidURL) = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }
    }

    func testRoute_WithNotRegisteredRouteOnEmptyRouter_ShouldFail() {

        XCTAssertRouteThrowsRouteNotFound(route: "scheme://host/")
        XCTAssertRouteThrowsRouteNotFound(route: "scheme://host/path")
        XCTAssertRouteThrowsRouteNotFound(route: "scheme://host/path/path")

        XCTAssertRouteThrowsRouteNotFound(route: "scheme:///")
        XCTAssertRouteThrowsRouteNotFound(route: "scheme:///path")
        XCTAssertRouteThrowsRouteNotFound(route: "scheme:///path/path")

        XCTAssertRouteThrowsRouteNotFound(route: "://host/")
        XCTAssertRouteThrowsRouteNotFound(route: "://host/path")
        XCTAssertRouteThrowsRouteNotFound(route: "://host/path/path")

        XCTAssertRouteThrowsRouteNotFound(route: "/")
        XCTAssertRouteThrowsRouteNotFound(route: "/path")
        XCTAssertRouteThrowsRouteNotFound(route: "/path/path")
    }

    func testRoute_WithRegisteredRouteOnDifferentScheme_ShouldFail() {

        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA://"], route: "://")
        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA://"], route: "schemeB://")
        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA:///"], route: "schemeB:///")
        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA://host"], route: "schemeB://host")
        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA://host/path"], route: "schemeB://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA://host/:parameter"], route: "schemeB://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA://host/*"], route: "schemeB://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA://host/**"], route: "schemeB://host/path/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["schemeA://host/**catchAll"], route: "schemeB://host/path/path")
    }

    func testRoute_WithRegisteredRouteOnDifferentHost_ShouldFail() {

        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://hostA"], route: "scheme:///")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://hostA"], route: "scheme://hostB")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://hostA/path"], route: "scheme://hostB/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://hostA/:parameter"], route: "scheme://hostB/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://hostA/*"], route: "scheme://hostB/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://hostA/**"], route: "scheme://hostB/path/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://hostA/**catchAll"], route: "scheme://hostB/path/path")

        XCTAssertRouteThrowsRouteNotFound(initial: ["://hostA"], route: "://hostB")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://hostA/path"], route: "://hostB/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://hostA/:parameter"], route: "://hostB/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://hostA/*"], route: "://hostB/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://hostA/**"], route: "://hostB/path/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://hostA/**catchAll"], route: "://hostB/path/path")
    }

    func testRoute_WithPartiallyMatchingRoute_ShouldFail() {

        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://host/path"], route: "scheme://host")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://host/path/path"], route: "scheme://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://host/:parameter/path"], route: "scheme://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://host/*/path"], route: "scheme://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["scheme://host/path/**"], route: "scheme://host/path")

        XCTAssertRouteThrowsRouteNotFound(initial: ["://host/path"], route: "://host")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://host/path/path"], route: "://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://host/:parameter/path"], route: "://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://host/*/path"], route: "://host/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["://host/path/**"], route: "://host/path")

        XCTAssertRouteThrowsRouteNotFound(initial: ["/path/path"], route: "/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["/path/path/path"], route: "/path/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["/path/:parameter/path"], route: "/path/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["/path/*/path"], route: "/path/path")
        XCTAssertRouteThrowsRouteNotFound(initial: ["/path/path/**"], route: "/path/path")
    }

    // MARK: - success

    // MARK: scheme

    func testRoute_WithMatchingScheme_ShouldSucceed() {

        XCTAssertRouteSucceeds(initial: [("http://", testHandler)], route: "http://")
        XCTAssertRouteSucceeds(initial: [("http://host/", testHandler)], route: "http://host/")
        XCTAssertRouteSucceeds(initial: [("http://host/path", testHandler)], route: "http://host/path")
    }

    func testRoute_WithWildcardSchemeAndMatchingRemainingRoute_ShouldSucceed() {

        XCTAssertRouteSucceeds(initial: [("://", testHandler)], route: "http://")
        XCTAssertRouteSucceeds(initial: [("://", testHandler)], route: "potato://")

        XCTAssertRouteSucceeds(initial: [("://host/", testHandler)], route: "http://host/")
        XCTAssertRouteSucceeds(initial: [("://host/", testHandler)], route: "potato://host/")

        XCTAssertRouteSucceeds(initial: [("://host/path", testHandler)], route: "http://host/path")
        XCTAssertRouteSucceeds(initial: [("://host/path", testHandler)], route: "potato://host/path")
    }

    func testRoute_WithExistingRouteOfWildcardSchemeFallback_ShouldSucceed() {

        // empty -> wildcard
        XCTAssertRouteSucceeds(initial: [("://", testHandler)], route: "://")
        XCTAssertRouteSucceeds(initial: [("://", testHandler)], route: "/")

        // nil -> wildcard
        XCTAssertRouteSucceeds(initial: [("/", testHandler)], route: "/")
        XCTAssertRouteSucceeds(initial: [("/", testHandler)], route: "://")
    }

    func testRoute_WithCaseInsensitiveMatchingScheme_ShouldSucceed() {
        XCTAssertRouteSucceeds(initial: [("HTTP://", testHandler)], route: "http://")
        XCTAssertRouteSucceeds(initial: [("HTTP://host/", testHandler)], route: "http://host/")
        XCTAssertRouteSucceeds(initial: [("HTTP://host/path", testHandler)], route: "http://host/path")
        XCTAssertRouteSucceeds(initial: [("HtTp://host/path", testHandler)], route: "http://host/path")

        XCTAssertRouteSucceeds(initial: [("http://", testHandler)], route: "HTTP://")
        XCTAssertRouteSucceeds(initial: [("http://host/", testHandler)], route: "HTTP://host/")
        XCTAssertRouteSucceeds(initial: [("http://host/path", testHandler)], route: "HTTP://host/path")
        XCTAssertRouteSucceeds(initial: [("http://host/path", testHandler)], route: "httP://host/path")
    }

    // MARK: host

    func testRoute_WithMatchingHost_ShouldSucceed() {

        XCTAssertRouteSucceeds(initial: [("://host/", testHandler)], route: "://host/")
        XCTAssertRouteSucceeds(initial: [("://host/path", testHandler)], route: "://host/path")
    }

    func testRoute_WithWildcardHostAndMatchingRemainingRoute_ShouldSucceed() {

        XCTAssertRouteSucceeds(initial: [("http:///", testHandler)], route: "http://host")
        XCTAssertRouteSucceeds(initial: [("http:///", testHandler)], route: "http://potato")

        XCTAssertRouteSucceeds(initial: [("http:///path", testHandler)], route: "http://host/path")
        XCTAssertRouteSucceeds(initial: [("http:///path", testHandler)], route: "http://potato/path")
    }

    func testRoute_WithDuplicateRouteOfWildcardHostFallback_ShouldSucceed() {

        // empty -> wildcard
        XCTAssertRouteSucceeds(initial: [(":///", testHandler)], route: ":///")
        XCTAssertRouteSucceeds(initial: [(":///", testHandler)], route: "://")
        XCTAssertRouteSucceeds(initial: [(":///", testHandler)], route: "/")
        XCTAssertRouteSucceeds(initial: [("://", testHandler)], route: ":///")
        XCTAssertRouteSucceeds(initial: [("://", testHandler)], route: "://")
        XCTAssertRouteSucceeds(initial: [("://", testHandler)], route: "/")

        // nil -> wildcard
        XCTAssertRouteSucceeds(initial: [("/", testHandler)], route: "/")
        XCTAssertRouteSucceeds(initial: [("/", testHandler)], route: "://")
        XCTAssertRouteSucceeds(initial: [("/", testHandler)], route: ":///")
    }

    func testRoute_WithCaseInsensitiveMatchingHost_ShouldSucceed() {
        XCTAssertRouteSucceeds(initial: [("http://HOST/", testHandler)], route: "http://host/")
        XCTAssertRouteSucceeds(initial: [("http://HOST/path", testHandler)], route: "http://host/path")
        XCTAssertRouteSucceeds(initial: [("http://HosT/path", testHandler)], route: "http://host/path")

        XCTAssertRouteSucceeds(initial: [("http://host/", testHandler)], route: "http://HOST/")
        XCTAssertRouteSucceeds(initial: [("http://host/path", testHandler)], route: "http://HOST/path")
        XCTAssertRouteSucceeds(initial: [("http://host/path", testHandler)], route: "http://hOSt/path")
    }

    // MARK: single level path

    func testRoute_WithMatchingSingleLevelPath_ShouldSucceed() {

        XCTAssertRouteSucceeds(initial: [("/path", testHandler)], route: "/path")
        XCTAssertRouteSucceeds(
            initial: [("/:variable", testHandler)],
            route: "/path",
            assertParams: ["variable": "path"]
        )
        XCTAssertRouteSucceeds(initial: [("/*", testHandler)], route: "/path")
        XCTAssertRouteSucceeds(initial: [("/**", testHandler)], route: "/path")
        XCTAssertRouteSucceeds(
            initial: [("/**variable", testHandler)],
            route: "/path",
            assertParams: ["variable": "path"]
        )
    }

    // MARK: multiple level path

    func testRoute_WithMatchingMultipleLevelPathStartingWithConstant_ShouldSucceed() {

        XCTAssertRouteSucceeds(initial: [("/some/path", testHandler)], route: "/some/path")
        XCTAssertRouteSucceeds(
            initial: [("/some/:variable", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "path"]
        )
        XCTAssertRouteSucceeds(initial: [("/some/*", testHandler)], route: "/some/path")
        XCTAssertRouteSucceeds(initial: [("/some/**", testHandler)], route: "/some/path")
        XCTAssertRouteSucceeds(
            initial: [("/some/**variable", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "path"]
        )
    }

    func testRoute_WithMatchingMultipleLevelPathStartingWithVariable_ShouldSucceed() {

        XCTAssertRouteSucceeds(
            initial: [("/:variable/path", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "some"]
        )
        XCTAssertRouteSucceeds(
            initial: [("/:variable/:another_variable", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "some", "another_variable": "path"]
        )
        XCTAssertRouteSucceeds(
            initial: [("/:variable/*", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "some"]
        )
        XCTAssertRouteSucceeds(
            initial: [("/:variable/**", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "some"]
        )
        XCTAssertRouteSucceeds(
            initial: [("/:variable/**another_variable", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "some", "another_variable": "path"]
        )
    }

    func testRoute_WithMatchingMultipleLevelPathStartingWithWildcard_ShouldSucceed() {

        XCTAssertRouteSucceeds(initial: [("/*/path", testHandler)], route: "/some/path")
        XCTAssertRouteSucceeds(
            initial: [("/*/:variable", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "path"]
        )
        XCTAssertRouteSucceeds(initial: [("/*/*", testHandler)], route: "/some/path")
        XCTAssertRouteSucceeds(initial: [("/*/**", testHandler)], route: "/some/path")
        XCTAssertRouteSucceeds(
            initial: [("/*/**variable", testHandler)],
            route: "/some/path",
            assertParams: ["variable": "path"]
        )
    }

    // MARK: prioritary

    func testRoute_WithMultipleMatchingSchemes_ShouldSucceedWithMostPioritaryRouteHandler() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("http:///some/path", handlerA),
                (":///some/path", handlerB)
            ],
            route: "http:///some/path"
        )
    }

    func testRoute_WithMultipleMatchingPaths_ShouldSucceedWithMostPioritaryRouteHandler() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("http://host/some/path", handlerA),
                ("http:///some/path", handlerB),
            ],
            route: "http://host/some/path"
        )
    }

    func testRoute_WithMultipleMatchingRoutesWithConstantRoute_ShouldSucceedWithMostPioritaryRouteHandler() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }
        let handlerC = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }
        let handlerD = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("/some/path", handlerA),
                ("/:variable/path", handlerB),
                ("/*/path", handlerC),
                ("/**", handlerD)
            ],
            route: "/some/path"
        )

        XCTAssertRouteSucceeds(
            initial: [
                ("/some/path", handlerA),
                ("/:variableA/:variableB", handlerB),
                ("/*/*", handlerC),
                ("/**", handlerD)
            ],
            route: "/some/path"
        )
    }

    func testRoute_WithMultipleMatchingRoutesWithVariableRoute_ShouldSucceedWithMostPioritaryRouteHandler() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }
        let handlerC = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("/:variable/path", handlerA),
                ("/*/path", handlerB),
                ("/**", handlerC)
            ],
            route: "/some/path",
            assertParams: ["variable": "some"]
        )

        XCTAssertRouteSucceeds(
            initial: [
                ("/:variableA/:variableB", handlerA),
                ("/*/*", handlerB),
                ("/**", handlerC)
            ],
            route: "/some/path",
            assertParams: ["variableA": "some", "variableB": "path"]
        )
    }

    func testRoute_WithMultipleMatchingRoutesWithWildcardRoute_ShouldSucceedWithMostPioritaryRouteHandler() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("/*/path", handlerA),
                ("/**", handlerB)
            ],
            route: "/some/path"
        )

        XCTAssertRouteSucceeds(
            initial: [
                ("/*/*", handlerA),
                ("/**", handlerB)
            ],
            route: "/some/path"
        )
    }

    // MARK: backtracking

    func testRoute_WithPartiallyMatchingSchemeRoute_ShouldSucceedByBacktrackingToNextMatchingRoute() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("://host/some/path", handlerA),
                ("http://host/some/path/*", handlerB), // will match this one first, then backtrack
            ],
            route: "http://host/some/path"
        )
    }

    func testRoute_WithPartiallyMatchingHostRoute_ShouldSucceedByBacktrackingToNextMatchingRoute() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("http:///some/path", handlerA),
                ("http://host/some/path/*", handlerB),  // will match this one first, then backtrack
            ],
            route: "http://host/some/path"
        )
    }

    func testRoute_WithSinglePartiallyMatchingPathRoute_ShouldSucceedByBacktrackingToNextMatchingRoute() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("http://host/some/path", handlerA),
                ("http://host/some/path/kaput", handlerB),  // will match this one first, then backtrack
            ],
            route: "http://host/some/path"
        )

        XCTAssertRouteSucceeds(
            initial: [
                ("http://host/:variable/path", handlerA),
                ("http://host/some/kaput", handlerB),  // will match this one first, then backtrack
            ],
            route: "http://host/some/path",
            assertParams: ["variable": "some"]
        )

        XCTAssertRouteSucceeds(
            initial: [
                ("http://host/*/path", handlerA),
                ("http://host/some/kaput", handlerB),  // will match this one first, then backtrack
            ],
            route: "http://host/some/path"
        )

        XCTAssertRouteSucceeds(
            initial: [
                ("http://host/**", handlerA),
                ("http://host/some/kaput", handlerB),  // will match this one first, then backtrack
            ],
            route: "http://host/some/path"
        )

        XCTAssertRouteSucceeds(
            initial: [
                ("http://host/**catchAll", handlerA),
                ("http://host/some/kaput", handlerB),  // will match this one first, then backtrack
            ],
            route: "http://host/some/path",
            assertParams: ["catchAll": "some/path"]
        )
    }

    func testRoute_WithMultiplePartiallyMatchingPathRoute_ShouldSucceedByBacktrackingToNextMatchingRoute() {

        let handlerA = makeTestHandler()
        let handlerB = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }
        let handlerC = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }
        let handlerD = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }
        let handlerE = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }
        let handlerF = makeTestHandler { _ in XCTFail("💥 unexpected handler called!") }

        XCTAssertRouteSucceeds(
            initial: [
                ("http://host/:variableA/:variableB/:variableC", handlerA), // 🎉
                ("http://host/some/path/nope", handlerB), // first match -> backtrack
                ("http://host/some/:variableA/:variableB/nyet", handlerC), // second match -> backtrack
                ("http://host/:variableA/path/*/nein", handlerD), // third match -> backtrack
                ("http://host/*/*/*", handlerE), // no match
                ("http://host/**potato", handlerF), // no match
            ],
            route: "http://host/some/path/somewhere",
            assertParams: ["variableA": "some", "variableB": "path", "variableC": "somewhere"]
        )

        XCTAssertRouteSucceeds(
            initial: [
                ("http://host/**catchAll", handlerA), // 🎉
                ("http://host/some/path/:variable", handlerB), // first match -> backtrack
                ("http://host/:variableA/:variableB/:variableC", handlerC), // second match -> backtrack
                ("http://host/*/:variableA/somewhere/nope", handlerD), // third match -> backtrack
                ("http:///**potato", handlerE), // no match
                ("/**superPotato", handlerF), // no match
            ],
            route: "http://host/some/path/somewhere/noice",
            assertParams: ["catchAll": "some/path/somewhere/noice"]
        )
    }

    // MARK: queryItems

    func testRoute_WithMatchingRouteContainingQueryItems_ShouldSucceedAndPropagateQueryItems() {

        let expectedQueryItems = [
            URLQueryItem(name: "team", value: "Mindera"),
            URLQueryItem(name: "user", value: "MrMinder"),
            URLQueryItem(name: "id", value: "1337"),
        ]

        XCTAssertRouteSucceeds(
            initial: [("http://", testHandler)],
            route: "http://?team=Mindera&user=MrMinder&id=1337",
            assertQueryItems: expectedQueryItems
        )

        XCTAssertRouteSucceeds(
            initial: [("http://host", testHandler)],
            route: "http://host?team=Mindera&user=MrMinder&id=1337",
            assertQueryItems: expectedQueryItems
        )

        XCTAssertRouteSucceeds(
            initial: [("http://host/some/path", testHandler)],
            route: "http://host/some/path?team=Mindera&user=MrMinder&id=1337",
            assertQueryItems: expectedQueryItems
        )
    }

    // MARK: route propagation

    func testRoute_WithMatchingRoute_ShouldPropagateRoute() {

        class TestRoute: Routable {

            var route: URL

            init(route: URL) { self.route = route }
        }

        struct TestHandler: RouteHandler {

            var didHandle: ((TestRoute, [String : String], [URLQueryItem]) -> Void)?

            public func handle(
                route: TestRoute,
                parameters: [String : String],
                queryItems: [URLQueryItem],
                completion: ((String) -> Void)?
            ) {

                didHandle?(route, parameters, queryItems)
            }
        }

        typealias TestRouter = Route.TrieRouter<TestRoute, String>

        let handleExpectation = expectation(description: "handle")
        defer { waitForExpectations(timeout: 1) }

        let url = "scheme://some/path".url()
        let route = TestRoute(route: url)

        let router = TestRouter()
        var handler = TestHandler()
        handler.didHandle = { _route, _, _ in

            XCTAssertIdentical(route, _route)
            handleExpectation.fulfill()
        }

        XCTAssertNoThrow(try router.register(url, handler: handler.eraseToAnyRouteHandler()))
        XCTAssertNoThrow(try router.route(route))
    }
}

// MARK: - helpers

private extension Route_TrieRouter_RouteTests {

    func XCTAssertRouteThrowsRouteNotFound(
        initial initialRoutes: [String] = [],
        route: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let router = TestRouter()

        XCTAssertNoThrow(
            try initialRoutes
                .map { $0.url(file: file, line: line) }
                .forEach { try router.register($0, handler: testHandler) },
            file: file,
            line: line
        )

        XCTAssertThrowsError(
            try router.route(
                route.url(file: file, line: line),
                handleCompletion: { XCTFail("💥 unexpected handle! \($0)", file: file, line: line) }
            ),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.TrieRouterError.routeNotFound = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }

    func XCTAssertRouteSucceeds(
        initial initialRoutes: [(String, AnyTestHandler)],
        route: String,
        assertParams expectedParams: Route.Parameters? = nil,
        assertQueryItems expectedQueryItems: [URLQueryItem]? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let router = TestRouter()
        let _route = route.url(file: file, line: line)

        let completion: (HandledRoute) -> Void = {

            let (url, params, queryItems) = $0

            XCTAssertEqual(url, _route, file: file, line: line)

            if let expectedParams = expectedParams {
                XCTAssertEqual(params, expectedParams, file: file, line: line)
            }

            if let expectedQueryItems = expectedQueryItems {
                XCTAssertEqual(queryItems, expectedQueryItems, file: file, line: line)
            }
        }

        XCTAssertNoThrow(
            try initialRoutes
                .map { ($0.0.url(file: file, line: line), $0.1) }
                .forEach(router.register),
            file: file,
            line: line
        )
        XCTAssertNoThrow(try router.route(_route, handleCompletion: completion), file: file, line: line)
    }

    func makeTestHandler(didHandle: ((HandledRoute) -> Void)? = nil) -> AnyTestHandler {

        let handler = TestHandler()
        handler.didHandle = didHandle

        return AnyTestHandler(handler)
    }
}
