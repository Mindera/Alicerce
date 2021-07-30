import XCTest
@testable import Alicerce

class Route_TrieRouter_UnregisterTests: XCTestCase {

    typealias TestRouter = Route.TrieRouter<URL, HandledRoute>
    typealias TestRouteTrieNode = Route.TrieNode<TestHandler>

    var testHandler = AnyRouteHandler(TestHandler())

    // MARK: - failure

    func testUnregister_WithNotRegisteredRouteOnEmptyRouter_ShouldFail() {

        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme://host/")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme://host/path")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme://host/:parameter")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme://host/*")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme://host/**")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme://host/**catchAll")

        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme:///")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme:///path")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme:///:parameter")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme:///*")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme:///**")
        XCTAssertUnregisterThrowsRouteNotFound(route: "scheme:///**catchAll")

        XCTAssertUnregisterThrowsRouteNotFound(route: "://host/")
        XCTAssertUnregisterThrowsRouteNotFound(route: "://host/path")
        XCTAssertUnregisterThrowsRouteNotFound(route: "://host/:parameter")
        XCTAssertUnregisterThrowsRouteNotFound(route: "://host/*")
        XCTAssertUnregisterThrowsRouteNotFound(route: "://host/**")
        XCTAssertUnregisterThrowsRouteNotFound(route: "://host/**catchAll")

        XCTAssertUnregisterThrowsRouteNotFound(route: "/")
        XCTAssertUnregisterThrowsRouteNotFound(route: "/path")
        XCTAssertUnregisterThrowsRouteNotFound(route: "/:parameter")
        XCTAssertUnregisterThrowsRouteNotFound(route: "/*")
        XCTAssertUnregisterThrowsRouteNotFound(route: "/**")
        XCTAssertUnregisterThrowsRouteNotFound(route: "/**catchAll")
    }

    func testUnregister_WithRegisteredRouteOnDifferentScheme_ShouldFail() {

        XCTAssertUnregisterThrowsRouteNotFound(initial: ["schemeA://"], route: "schemeB://")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["schemeA:///"], route: "schemeB:///")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["schemeA://host/"], route: "schemeB://host/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["schemeA://host/path"], route: "schemeB://host/path")
        XCTAssertUnregisterThrowsRouteNotFound(
            initial: ["schemeA://host/:parameter"],
            route: "schemeB://host/:parameter"
        )
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["schemeA://host/*"], route: "schemeB://host/*")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["schemeA://host/**"], route: "schemeB://host/**")
        XCTAssertUnregisterThrowsRouteNotFound(
            initial: ["schemeA://host/**catchAll"],
            route: "schemeB://host/**catchAll"
        )
    }

    func testUnregister_WithRegisteredRouteOnDifferentHost_ShouldFail() {

        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://hostA/"], route: "scheme://hostB/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://hostA/path"], route: "scheme://hostB/path")
        XCTAssertUnregisterThrowsRouteNotFound(
            initial: ["scheme://hostA/:parameter"],
            route: "scheme://hostB/:parameter"
        )
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://hostA/*"], route: "scheme://hostB/*")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://hostA/**"], route: "scheme://hostB/**")
        XCTAssertUnregisterThrowsRouteNotFound(
            initial: ["scheme://hostA/**catchAll"],
            route: "scheme://hostB/**catchAll"
        )

        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/hostA/"], route: "/hostB/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/hostA/path"], route: "/hostB/path")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/hostA/:parameter"], route: "/hostB/:parameter")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/hostA/*"], route: "/hostB/*")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/hostA/**"], route: "/hostB/**")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/hostA/**catchAll"], route: "/hostB/**catchAll")
    }

    func testUnregister_WithPartiallyMatchingRoute_ShouldFail() {

        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://"], route: "scheme://host/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://host/path"], route: "scheme://host/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://host/path/path"], route: "scheme://host/path")
        XCTAssertUnregisterThrowsRouteNotFound(
            initial: ["scheme://host/:parameter/path"],
            route: "scheme://host/:parameter"
        )
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://host/*/path"], route: "scheme://host/*")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["scheme://host/path/path"], route: "scheme://host/path/**")

        XCTAssertUnregisterThrowsRouteNotFound(initial: ["://"], route: "://host/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["://host/path"], route: "://host/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["://host/path/path"], route: "://host/path")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["://host/:parameter/path"], route: "://host/:parameter")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["://host/*/path"], route: "://host/*")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["://host/path/path"], route: "://host/path/**")

        XCTAssertUnregisterThrowsRouteNotFound(initial: ["://"], route: "/host/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/host/path"], route: "/host/")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/host/path/path"], route: "/host/path")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/host/:parameter/path"], route: "/host/:parameter")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/host/*/path"], route: "/host/*")
        XCTAssertUnregisterThrowsRouteNotFound(initial: ["/host/path/path"], route: "/host/path/**")
    }

    func testUnregister_WithMisplacedCatchAll_ShouldFail() {

        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/path")
        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/:parameter")
        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/*")
        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/**")
        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**parameter/**")
        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/**parameter")

        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(initial: ["/path"], route: "/path/**/path")
        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(
            initial: ["/:parameterA"],
            route: "/:parameterA/**/:parameterB"
        )
        XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(initial: ["/*"], route: "/*/**/*")
    }

    func testUnregister_WithInvalidRouteComponent_ShouldFail() {

        let router = TestRouter()

        XCTAssertThrowsError(try router.unregister("/*foo".url()), "🔥 Unexpected success!") {
            guard case Route.TrieRouterError.invalidRoute(.invalidComponent(.invalidWildcard)) = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }

        XCTAssertThrowsError(try router.unregister("/:".url()), "🔥 Unexpected success!") {
            guard case Route.TrieRouterError.invalidRoute(.invalidComponent(.emptyParameterName)) = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }
    }

    // MARK: - success

    func testUnregister_WithExistingRoute_ShouldSucceed() {

        XCTAssertUnregisterSucceeds(route: "scheme://host/")
        XCTAssertUnregisterSucceeds(route: "scheme://host/path")
        XCTAssertUnregisterSucceeds(route: "scheme://host/:parameter")
        XCTAssertUnregisterSucceeds(route: "scheme://host/*")
        XCTAssertUnregisterSucceeds(route: "scheme://host/**")
        XCTAssertUnregisterSucceeds(route: "scheme://host/**catchAll")

        XCTAssertUnregisterSucceeds(route: "scheme://")
        XCTAssertUnregisterSucceeds(route: "scheme:///")
        XCTAssertUnregisterSucceeds(route: "scheme:///path")
        XCTAssertUnregisterSucceeds(route: "scheme:///:parameter")
        XCTAssertUnregisterSucceeds(route: "scheme:///*")
        XCTAssertUnregisterSucceeds(route: "scheme:///**")
        XCTAssertUnregisterSucceeds(route: "scheme:///**catchAll")

        XCTAssertUnregisterSucceeds(route: ":///")
        XCTAssertUnregisterSucceeds(route: "://host/")
        XCTAssertUnregisterSucceeds(route: "://host/path")
        XCTAssertUnregisterSucceeds(route: "://host/:parameter")
        XCTAssertUnregisterSucceeds(route: "://host/*")
        XCTAssertUnregisterSucceeds(route: "://host/**")
        XCTAssertUnregisterSucceeds(route: "://host/**catchAll")

        XCTAssertUnregisterSucceeds(route: "/")
        XCTAssertUnregisterSucceeds(route: "/path")
        XCTAssertUnregisterSucceeds(route: "/:parameter")
        XCTAssertUnregisterSucceeds(route: "/*")
        XCTAssertUnregisterSucceeds(route: "/**")
        XCTAssertUnregisterSucceeds(route: "/**catchAll")
    }

    func testUnregister_WithExistingMultiComponentRoute_ShouldSucceed() {

        XCTAssertUnregisterSucceeds(route: "scheme://host/path/path")
        XCTAssertUnregisterSucceeds(route: "scheme://host/path/:parameter")
        XCTAssertUnregisterSucceeds(route: "scheme://host/path/*")
        XCTAssertUnregisterSucceeds(route: "scheme://host/path/**")
        XCTAssertUnregisterSucceeds(route: "scheme://host/path/**catchAll")
    }

    func testUnregister_WithExistingRouteOfWildcardSchemeFallback_ShouldSucceed() {

        // empty -> wildcard
        XCTAssertUnregisterSucceeds(initial: "://", route: "://")
        XCTAssertUnregisterSucceeds(initial: "://", route: "/")

        // nil -> wildcard
        XCTAssertUnregisterSucceeds(initial: "/", route: "/")
        XCTAssertUnregisterSucceeds(initial: "/", route: "://")
    }

    func testUnregister_WithDuplicateRouteOfWildcardHostFallback_ShouldSucceed() {

        // empty -> wildcard
        XCTAssertUnregisterSucceeds(initial: ":///", route: ":///")
        XCTAssertUnregisterSucceeds(initial: ":///", route: "://")
        XCTAssertUnregisterSucceeds(initial: ":///", route: "/")
        XCTAssertUnregisterSucceeds(initial: "://", route: ":///")
        XCTAssertUnregisterSucceeds(initial: "://", route: "://")
        XCTAssertUnregisterSucceeds(initial: "://", route: "/")

        // nil -> wildcard
        XCTAssertUnregisterSucceeds(initial: "/", route: "/")
        XCTAssertUnregisterSucceeds(initial: "/", route: "://")
        XCTAssertUnregisterSucceeds(initial: "/", route: ":///")
    }
}

// MARK: - helpers

private extension Route_TrieRouter_UnregisterTests {

    func XCTAssertUnregisterThrowsRouteNotFound(
        initial: [String] = [],
        route: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let router = TestRouter()

        XCTAssertNoThrow(
            try initial
                .map { $0.url(file: file, line: line) }
                .forEach { try router.register($0, handler: testHandler) },
            file: file,
            line: line
        )

        XCTAssertThrowsError(
            try router.unregister(route.url(file: file, line: line)),
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

    func XCTAssertUnregisterThrowsInvalidRouteWithMisplacedCatchAll(
        initial initialRoutes: [String] = ["/"],
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
            try router.unregister(route.url(file: file, line: line)),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.TrieRouterError.invalidRoute(.misplacedCatchAllComponent) = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }

    func XCTAssertUnregisterSucceeds(
        initial initialRoute: String? = nil,
        route: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let router = TestRouter()

        let _route = route.url(file: file, line: line)
        let registerRoute = initialRoute?.url(file: file, line: line) ?? _route

        XCTAssertNoThrow(try router.register(registerRoute, handler: testHandler), file: file, line: line)
        XCTAssert(try router.unregister(_route) === testHandler, file: file, line: line)
    }
}
