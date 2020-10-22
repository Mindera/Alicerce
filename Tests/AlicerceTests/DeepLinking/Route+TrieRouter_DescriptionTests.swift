import XCTest
@testable import Alicerce

class Route_TrieRouter_DescriptionTests: XCTestCase {

    struct TestHandler: RouteHandler, CustomStringConvertible {

        let tag: String

        public func handle(
            route: URL,
            parameters: [String : String],
            queryItems: [URLQueryItem],
            completion: ((String) -> Void)?
        ) {}

        public var description: String { return tag }
    }

    typealias TestRouter = Route.TrieRouter<String>

    func testDescription_ShouldMatchValues() {

        let router = TestRouter()

        do {
            try router.register("/some/path".url(), handler: testHandler("A"))
            try router.register("/some/path/**".url(), handler: testHandler("B"))
            try router.register("/some/path/*/:parameterA".url(), handler: testHandler("C"))

            try router.register(":///hostA/another/path".url(), handler: testHandler("D"))
            try router.register(":///hostA/another/:parameterA/:parameterB".url(), handler: testHandler("E"))
            try router.register(
                ":///host/another/:parameterA/:parameterB/**parameterC".url(),
                handler: testHandler("F")
            )

            try router.register(":///hostB/:parameterA/before/path".url(), handler: testHandler("G"))
            try router.register(":///hostB/:parameterA/:parameterB/path/*".url(), handler: testHandler("H"))
            try router.register(":///hostB/:parameterA/:parameterB/**".url(), handler: testHandler("I"))
            try router.register(":///hostB/:parameterA/*/path/*".url(), handler: testHandler("J"))

            try router.register("schemeA://hostC/*/yet/another/path".url(), handler: testHandler("K"))
            try router.register("schemeA://hostC/*/yet/another/:parameterA/*".url(), handler: testHandler("L"))
            try router.register("schemeA://hostC/*/yet/another/**".url(), handler: testHandler("M"))

            try router.register("schemeA:///**catchAll".url(), handler: testHandler("N"))

            try router.register("schemeB://".url(), handler: testHandler("O"))
            try router.register("schemeB://hostA/".url(), handler: testHandler("P"))
            try router.register("schemeB://hostB/path".url(), handler: testHandler("Q"))
            try router.register("schemeB://hostB/path/*".url(), handler: testHandler("R"))
        } catch {
            return XCTFail("🔥 Failed to add routes with error: \(error)!")
        }

        XCTAssertEqual(
            router.description,
            """
            ├──┬ schemeb
            │  ├──┬ hosta
            │  │  └──● AnyRouteHandler<String>(P)
            │  │
            │  ├──┬ hostb
            │  │  └──┬ path
            │  │     ├──┬ *
            │  │     │  └──● AnyRouteHandler<String>(R)
            │  │     │
            │  │     └──● AnyRouteHandler<String>(Q)
            │  │
            │  └──┬ *
            │     └──● AnyRouteHandler<String>(O)
            │
            ├──┬ schemea
            │  ├──┬ hostc
            │  │  └──┬ *
            │  │     └──┬ yet
            │  │        └──┬ another
            │  │           ├──┬ path
            │  │           │  └──● AnyRouteHandler<String>(K)
            │  │           │
            │  │           ├──┬ :parameterA
            │  │           │  └──┬ *
            │  │           │     └──● AnyRouteHandler<String>(L)
            │  │           │
            │  │           └──┬ **
            │  │              └──● AnyRouteHandler<String>(M)
            │  │
            │  └──┬ *
            │     └──┬ **catchAll
            │        └──● AnyRouteHandler<String>(N)
            │
            └──┬ *
               └──┬ *
                  ├──┬ some
                  │  └──┬ path
                  │     ├──┬ *
                  │     │  └──┬ :parameterA
                  │     │     └──● AnyRouteHandler<String>(C)
                  │     │
                  │     ├──┬ **
                  │     │  └──● AnyRouteHandler<String>(B)
                  │     │
                  │     └──● AnyRouteHandler<String>(A)
                  │
                  ├──┬ host
                  │  └──┬ another
                  │     └──┬ :parameterA
                  │        └──┬ :parameterB
                  │           └──┬ **parameterC
                  │              └──● AnyRouteHandler<String>(F)
                  │
                  ├──┬ hostA
                  │  └──┬ another
                  │     ├──┬ path
                  │     │  └──● AnyRouteHandler<String>(D)
                  │     │
                  │     └──┬ :parameterA
                  │        └──┬ :parameterB
                  │           └──● AnyRouteHandler<String>(E)
                  │
                  └──┬ hostB
                     └──┬ :parameterA
                        ├──┬ before
                        │  └──┬ path
                        │     └──● AnyRouteHandler<String>(G)
                        │
                        ├──┬ :parameterB
                        │  ├──┬ path
                        │  │  └──┬ *
                        │  │     └──● AnyRouteHandler<String>(H)
                        │  │
                        │  └──┬ **
                        │     └──● AnyRouteHandler<String>(I)
                        │
                        └──┬ *
                           └──┬ path
                              └──┬ *
                                 └──● AnyRouteHandler<String>(J)
            """
        )
    }

    private func testHandler(_ tag: String) -> AnyRouteHandler<String> { return AnyRouteHandler(TestHandler(tag: tag)) }
}
