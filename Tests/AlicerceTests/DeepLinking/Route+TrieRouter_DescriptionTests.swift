import XCTest
@testable import Alicerce

class Route_TrieRouter_DescriptionTests: XCTestCase {

    struct Payload {}

    struct TestHandler: RouteHandler, CustomStringConvertible {

        let tag: String

        public func handle(
            route: URL,
            parameters: [String : String],
            queryItems: [URLQueryItem],
            completion: ((Payload) -> Void)?
        ) {}

        public var description: String { tag }
    }

    typealias TestRouter = Route.TrieRouter<URL, Payload>

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
            │  │  └──● AnyRouteHandler<URL, Payload>(P)
            │  │
            │  ├──┬ hostb
            │  │  └──┬ path
            │  │     ├──┬ *
            │  │     │  └──● AnyRouteHandler<URL, Payload>(R)
            │  │     │
            │  │     └──● AnyRouteHandler<URL, Payload>(Q)
            │  │
            │  └──┬ *
            │     └──● AnyRouteHandler<URL, Payload>(O)
            │
            ├──┬ schemea
            │  ├──┬ hostc
            │  │  └──┬ *
            │  │     └──┬ yet
            │  │        └──┬ another
            │  │           ├──┬ path
            │  │           │  └──● AnyRouteHandler<URL, Payload>(K)
            │  │           │
            │  │           ├──┬ :parameterA
            │  │           │  └──┬ *
            │  │           │     └──● AnyRouteHandler<URL, Payload>(L)
            │  │           │
            │  │           └──┬ **
            │  │              └──● AnyRouteHandler<URL, Payload>(M)
            │  │
            │  └──┬ *
            │     └──┬ **catchAll
            │        └──● AnyRouteHandler<URL, Payload>(N)
            │
            └──┬ *
               └──┬ *
                  ├──┬ some
                  │  └──┬ path
                  │     ├──┬ *
                  │     │  └──┬ :parameterA
                  │     │     └──● AnyRouteHandler<URL, Payload>(C)
                  │     │
                  │     ├──┬ **
                  │     │  └──● AnyRouteHandler<URL, Payload>(B)
                  │     │
                  │     └──● AnyRouteHandler<URL, Payload>(A)
                  │
                  ├──┬ host
                  │  └──┬ another
                  │     └──┬ :parameterA
                  │        └──┬ :parameterB
                  │           └──┬ **parameterC
                  │              └──● AnyRouteHandler<URL, Payload>(F)
                  │
                  ├──┬ hostA
                  │  └──┬ another
                  │     ├──┬ path
                  │     │  └──● AnyRouteHandler<URL, Payload>(D)
                  │     │
                  │     └──┬ :parameterA
                  │        └──┬ :parameterB
                  │           └──● AnyRouteHandler<URL, Payload>(E)
                  │
                  └──┬ hostB
                     └──┬ :parameterA
                        ├──┬ before
                        │  └──┬ path
                        │     └──● AnyRouteHandler<URL, Payload>(G)
                        │
                        ├──┬ :parameterB
                        │  ├──┬ path
                        │  │  └──┬ *
                        │  │     └──● AnyRouteHandler<URL, Payload>(H)
                        │  │
                        │  └──┬ **
                        │     └──● AnyRouteHandler<URL, Payload>(I)
                        │
                        └──┬ *
                           └──┬ path
                              └──┬ *
                                 └──● AnyRouteHandler<URL, Payload>(J)
            """
        )
    }

    private func testHandler(_ tag: String) -> AnyRouteHandler<URL, Payload> { AnyRouteHandler(TestHandler(tag: tag)) }
}
