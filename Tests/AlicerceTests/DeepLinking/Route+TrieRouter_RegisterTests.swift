import XCTest
@testable import Alicerce

typealias HandledRoute = (URL, [String: String], [URLQueryItem])

final class TestHandler: RouteHandler {

    var didHandle: ((HandledRoute) -> Void)? = nil

    public func handle(
        route: URL,
        parameters: [String: String],
        queryItems: [URLQueryItem],
        completion: ((HandledRoute) -> Void)?
    ) {
        
        didHandle?((route, parameters, queryItems))
        completion?((route, parameters, queryItems))
    }
}

class Route_TrieRouter_RegisterTests: XCTestCase {

    typealias TestRouter = Route.TrieRouter<HandledRoute>
    typealias TestRouteTrieNode = Route.TrieNode<TestHandler>

    var testHandler = AnyRouteHandler<HandledRoute>(TestHandler())

    // MARK: - failure

    func testRegister_WithDuplicateRoute_ShouldFail() {

        XCTAssertRegisterThrowsDuplicateRoute(route: "scheme://")
        XCTAssertRegisterThrowsDuplicateRoute(route: "scheme:///")
        XCTAssertRegisterThrowsDuplicateRoute(route: "scheme://host/")
        XCTAssertRegisterThrowsDuplicateRoute(route: "scheme://host/some/path")
        XCTAssertRegisterThrowsDuplicateRoute(route: "scheme://host/some/:parameter")
        XCTAssertRegisterThrowsDuplicateRoute(route: "scheme://host/*/:parameter/path")
    }

    func testRegister_WithDuplicateRouteOfWildcardSchemeFallback_ShouldFail() {

        // empty -> wildcard
        XCTAssertRegisterThrowsDuplicateRoute(initial: "://", route: "://")
        XCTAssertRegisterThrowsDuplicateRoute(initial: "://", route: "/")

        // nil -> wildcard
        XCTAssertRegisterThrowsDuplicateRoute(initial: "/", route: "/")
        XCTAssertRegisterThrowsDuplicateRoute(initial: "/", route: "://")
    }

    func testRegister_WithDuplicateRouteOfWildcardHostFallback_ShouldFail() {

        // empty -> wildcard
        XCTAssertRegisterThrowsDuplicateRoute(initial: ":///", route: ":///")
        XCTAssertRegisterThrowsDuplicateRoute(initial: ":///", route: "://")
        XCTAssertRegisterThrowsDuplicateRoute(initial: ":///", route: "/")
        XCTAssertRegisterThrowsDuplicateRoute(initial: "://", route: ":///")
        XCTAssertRegisterThrowsDuplicateRoute(initial: "://", route: "://")
        XCTAssertRegisterThrowsDuplicateRoute(initial: "://", route: "/")

        // nil -> wildcard
        XCTAssertRegisterThrowsDuplicateRoute(initial: "/", route: "/")
        XCTAssertRegisterThrowsDuplicateRoute(initial: "/", route: "://")
        XCTAssertRegisterThrowsDuplicateRoute(initial: "/", route: ":///")
    }

    func testRegister_WithDuplicateParameterName_ShouldFail() {

        XCTAssertRegisterThrowsInvalidRouteWithDuplicateParameterName(
            route: "/:parameter/path/:parameter",
            parameterName: "parameter"
        )
        XCTAssertRegisterThrowsInvalidRouteWithDuplicateParameterName(
            route: "/:parameter/path/**parameter",
            parameterName: "parameter"
        )
    }

    func testRegister_WithMisplacedCatchAll_ShouldFail() {

        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/path")
        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**var/path", catchAllName: "var")

        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/:parameter")
        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**var/:parameter", catchAllName: "var")

        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/*")
        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**var/*", catchAllName: "var")

        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/**")
        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**var/**", catchAllName: "var")

        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**/**var")
        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/**foo/**var", catchAllName: "foo")

        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/path/**/path")
        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/path/**var/path", catchAllName: "var")

        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/:parameterA/**/:parameterB")
        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(
            route: "/:parameterA/**var/:parameterB",
            catchAllName: "var"
        )

        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/*/**/*")
        XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(route: "/*/**var/*", catchAllName: "var")
    }

    func testRegister_WithConflictingParameterRoute_ShouldFail() {

        let router = TestRouter()

        let route = "scheme://path/:parameterA".url()
        let conflictingRoute = "scheme://path/:parameterB".url()

        XCTAssertNoThrow(try router.register(route, handler: testHandler))
        XCTAssertThrowsError(
            try router.register(conflictingRoute, handler: testHandler),
            "🔥 Unexpected success!"
        ) {
            guard
                case Route.TrieRouterError.conflictingRoute(.parameterComponent("parameterA", "parameterB")) = $0
            else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }
    }

    func testRegister_WithConflictingCatchAllRoute_ShouldFail() {

        XCTAssertRegisterThrowsConflictingRouteFromCatchAll(
            initial: "/**parameter",
            conflicting: "/**",
            existingCatchAllName: "parameter",
            newCatchAllName: nil
        )
        XCTAssertRegisterThrowsConflictingRouteFromCatchAll(
            initial: "/**",
            conflicting: "/**parameter",
            existingCatchAllName: nil,
            newCatchAllName: "parameter"
        )
        XCTAssertRegisterThrowsConflictingRouteFromCatchAll(
            initial: "/**parameterA",
            conflicting: "/**parameterB",
            existingCatchAllName: "parameterA",
            newCatchAllName: "parameterB"
        )
    }

    func testRegister_WithInvalidRouteComponent_ShouldFail() {

        let router = TestRouter()

        XCTAssertThrowsError(try router.register("/*foo".url(), handler: testHandler), "🔥 Unexpected success!") {
            guard case Route.TrieRouterError.invalidRoute(.invalidComponent(.invalidWildcard)) = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }

        XCTAssertThrowsError(try router.register("/:".url(), handler: testHandler), "🔥 Unexpected success!") {
            guard case Route.TrieRouterError.invalidRoute(.invalidComponent(.emptyParameterName)) = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }
    }

    // MARK: - success

    func testRegister_WithEmptyScheme_ShouldSucceed() {

        XCTAssertNoThrow(try TestRouter().register(":/host/path".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register(":/host/:parameter".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register(":/host/*".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register(":/host/**".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register(":/host/**catchAll".url(), handler: testHandler))
    }

    func testRegister_WithEmptyHost_ShouldSucceed() {

        XCTAssertNoThrow(try TestRouter().register("/path".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("/:parameter".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("/*".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("/**".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("/**catchAll".url(), handler: testHandler))

        XCTAssertNoThrow(try TestRouter().register("scheme:///path".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("scheme:///:parameter".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("scheme:///*".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("scheme:///**".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("scheme:///**catchAll".url(), handler: testHandler))
    }

    func testRegister_WithFullURL_ShouldSucceed() {

        XCTAssertNoThrow(try TestRouter().register("scheme://host/path".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("scheme://host/:parameter".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("scheme://host/*".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("scheme://host/**".url(), handler: testHandler))
        XCTAssertNoThrow(try TestRouter().register("scheme://host/**catchAll".url(), handler: testHandler))
    }

    func testRegister_WithSameRouteOnDifferentScheme_ShouldSucceed() {

        let routerA = TestRouter()
        XCTAssertNoThrow(try routerA.register("schemeA://host/path".url(), handler: testHandler))
        XCTAssertNoThrow(try routerA.register("schemeB://host/path".url(), handler: testHandler))

        let routerB = TestRouter()
        XCTAssertNoThrow(try routerB.register("schemeA://host/:parameter".url(), handler: testHandler))
        XCTAssertNoThrow(try routerB.register("schemeB://host/:parameter".url(), handler: testHandler))

        let routerC = TestRouter()
        XCTAssertNoThrow(try routerC.register("schemeA://host/*".url(), handler: testHandler))
        XCTAssertNoThrow(try routerC.register("schemeB://host/*".url(), handler: testHandler))

        let routerD = TestRouter()
        XCTAssertNoThrow(try routerD.register("schemeA://host/**".url(), handler: testHandler))
        XCTAssertNoThrow(try routerD.register("schemeB://host/**".url(), handler: testHandler))

        let routerE = TestRouter()
        XCTAssertNoThrow(try routerE.register("schemeA://host/**catchAll".url(), handler: testHandler))
        XCTAssertNoThrow(try routerE.register("schemeB://host/**catchAll".url(), handler: testHandler))
    }

    func testRegister_WithSameRouteOnDifferentHost_ShouldSucceed() {

        let routerA = TestRouter()
        XCTAssertNoThrow(try routerA.register("scheme://hostA/path".url(), handler: testHandler))
        XCTAssertNoThrow(try routerA.register("scheme://hostB/path".url(), handler: testHandler))

        let routerB = TestRouter()
        XCTAssertNoThrow(try routerB.register("scheme://hostA/:parameter".url(), handler: testHandler))
        XCTAssertNoThrow(try routerB.register("scheme://hostB/:parameter".url(), handler: testHandler))

        let routerC = TestRouter()
        XCTAssertNoThrow(try routerC.register("scheme://hostA/*".url(), handler: testHandler))
        XCTAssertNoThrow(try routerC.register("scheme://hostB/*".url(), handler: testHandler))

        let routerD = TestRouter()
        XCTAssertNoThrow(try routerD.register("scheme://hostA/**".url(), handler: testHandler))
        XCTAssertNoThrow(try routerD.register("scheme://hostB/**".url(), handler: testHandler))

        let routerE = TestRouter()
        XCTAssertNoThrow(try routerE.register("scheme://hostA/**catchAll".url(), handler: testHandler))
        XCTAssertNoThrow(try routerE.register("scheme://hostB/**catchAll".url(), handler: testHandler))
    }
}

// MARK: - helpers

private extension Route_TrieRouter_RegisterTests {

    func XCTAssertRegisterThrowsDuplicateRoute(
        initial initialRoute: String? = nil,
        route: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let router = TestRouter()

        let _route = route.url(file: file, line: line)
        let registerRoute = initialRoute?.url(file: file, line: line) ?? _route

        XCTAssertNoThrow(try router.register(registerRoute, handler: testHandler), file: file, line: line)
        XCTAssertThrowsError(
            try router.register(_route, handler: testHandler),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.TrieRouterError.duplicateRoute = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }

    func XCTAssertRegisterThrowsInvalidRouteWithDuplicateParameterName(
        route: String,
        parameterName: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let router = TestRouter()

        XCTAssertThrowsError(
            try router.register(route.url(file: file, line: line), handler: testHandler),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.TrieRouterError.invalidRoute(.duplicateParameterName(parameterName)) = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }

    func XCTAssertRegisterThrowsInvalidRouteWithMisplacedCatchAll(
        route: String,
        catchAllName: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let router = TestRouter()

        XCTAssertThrowsError(
            try router.register(route.url(file: file, line: line), handler: testHandler),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.TrieRouterError.invalidRoute(.misplacedCatchAllComponent(catchAllName)) = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }

    func XCTAssertRegisterThrowsConflictingRouteFromCatchAll(
        initial initialRoute: String,
        conflicting conflictingRoute: String,
        existingCatchAllName: String?,
        newCatchAllName: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let router = TestRouter()

        XCTAssertNoThrow(
            try router.register(initialRoute.url(file: file, line: line), handler: testHandler),
            file: file,
            line: line
        )
        XCTAssertThrowsError(
            try router.register(conflictingRoute.url(file: file, line: line), handler: testHandler),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard
                case Route.TrieRouterError.conflictingRoute(
                    .catchAllComponent(existingCatchAllName, newCatchAllName)
                ) = $0
            else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }
}
