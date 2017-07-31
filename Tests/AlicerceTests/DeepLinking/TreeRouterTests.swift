//
//  TreeRouterTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

typealias HandledRoute = (URL, [String : String], [URLQueryItem])

final class TestHandler: RouteHandler {

    public func handle(route: URL,
                       parameters: [String : String],
                       queryItems: [URLQueryItem],
                       completion: ((HandledRoute) -> Void)?) {
        completion?(route, parameters, queryItems)
    }
}

class TreeRouterTests: XCTestCase {

    typealias TestRouter = TreeRouter<TestHandler, HandledRoute>
    typealias TestRouteTree = Route.Tree<TestHandler>

    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    var router: TestRouter!
    var testHandler: TestHandler!
    
    override func setUp() {
        super.setUp()

        router = TestRouter()
        testHandler = TestHandler()
    }
    
    override func tearDown() {
        router = nil
        testHandler = nil

        super.tearDown()
    }
    
    // MARK: - register

    // MARK: error

    func testRegister_WithDuplicateRouteEndingInEmptyComponentOnAlreadyExistentRoute_ShouldFailWithDuplicateRoute() {

        let validRoute = URL(string: "scheme://host")!
        let duplicateRoute = URL(string: "scheme://host/")!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.register(duplicateRoute, handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.duplicateRoute {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithDuplicateRouteWithoutEndingEmptyComponentOnAlreadyExistentRouteWithEmptyComponent_ShouldFailWithDuplicateRoute() {

        let validRoute = URL(string: "scheme://host/")!
        let duplicateRoute = URL(string: "scheme://host")!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.register(duplicateRoute, handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.duplicateRoute {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithDuplicateRouteWithPathEndingInEmptyComponentOnAlreadyExistentRoute_ShouldFailWithDuplicateRoute() {

        let validRoute = URL(string: "scheme://host/path")!
        let duplicateRoute = URL(string: "scheme://host/path/")!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.register(duplicateRoute, handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.duplicateRoute {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithDuplicateRouteWithPathWithoutEndingEmptyComponentOnAlreadyExistentRouteWithEmptyComponent_ShouldFailWithDuplicateRoute() {

        let validRoute = URL(string: "scheme://host/path/")!
        let duplicateRoute = URL(string: "scheme://host/path")!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.register(duplicateRoute, handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.duplicateRoute {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithConflictingVariableRouteOnAlreadyExistentVariableRoute_ShouldFailWithInvalidRoute() {

        let existingParameterName = "variable"
        let validRoute = URL(string: "scheme:///:" + existingParameterName)!

        let conflictingParameterNameA = "conflict"
        let conflictingParameterNameB = "*"
        let invalidRouteA = URL(string: "scheme:///:" + conflictingParameterNameA)!
        let invalidRouteB = URL(string: "scheme:///" + conflictingParameterNameB)!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        // variable value vs variable value conflict
        do {
            try router.register(invalidRouteA, handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch let TestRouter.Error.invalidRoute(.conflictingVariableComponent(existing, new)) {
            // expected error 💪
            XCTAssertEqual(existing, existingParameterName)
            XCTAssertEqual(new, conflictingParameterNameA)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // variable value vs variable wildcard conflict
        do {
            try router.register(invalidRouteB, handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch let TestRouter.Error.invalidRoute(.conflictingVariableComponent(existing, new)) {
            // expected error 💪
            XCTAssertEqual(existing, existingParameterName)
            XCTAssertEqual(new, conflictingParameterNameB)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: success

    func testRegister_WithValidRouteWithSchemeAndHost_ShouldSucceed() {

        let validRoute = URL(string: "scheme://host/path/")!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithValidRouteWithEmptyHost_ShouldSucceed() {

        let validRoute = URL(string: "scheme:///path/")!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithValidRouteWithEmptyScheme_ShouldSucceed() {

        let validRoute = URL(string: "://host/path/")!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithValidRouteWithEmptySchemeAndHost_ShouldSucceed() {

        let validRoute = URL(string: ":///path/")!

        do {
            try router.register(validRoute, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithTwoEqualRoutesOnDifferentSchemes_ShouldSucceed() {

        let validRouteA = URL(string: "schemeA://host/path/")!
        let validRouteB = URL(string: "schemeB://host/path/")!

        do {
            try router.register(validRouteA, handler: testHandler)
            try router.register(validRouteB, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithTwoEqualRoutesOnDifferentSchemesWithEmptyHost_ShouldSucceed() {

        let validRouteA = URL(string: "schemeA:///path/")!
        let validRouteB = URL(string: "schemeB:///path/")!

        do {
            try router.register(validRouteA, handler: testHandler)
            try router.register(validRouteB, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRegister_WithTwoEqualRoutesOnDifferentHosts_ShouldSucceed() {

        let validRouteA = URL(string: "scheme://hostA/path/")!
        let validRouteB = URL(string: "scheme://hostB/path/")!

        do {
            try router.register(validRouteA, handler: testHandler)
            try router.register(validRouteB, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: - unregister

    // MARK: error

    // single path

    func testUnregister_WithNonExistentRouteAndScheme_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme://host/path")!
        do {
            let _ = try router.unregister(route)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithNonExistentRouteAndSchemeAndEmptyHost_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme:///path")!
        do {
            let _ = try router.unregister(route)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithNonExistentRouteAndExistentScheme_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme://host/path")!
        let nonExistentRoute = URL(string: "scheme://host/non-existent")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(nonExistentRoute)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithNonExistentRouteAndExistentSchemeAndEmptyHost_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme:///path")!
        let nonExistentRoute = URL(string: "scheme:///non-existent")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(nonExistentRoute)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithNonExistentSchemeOnlyRouteAndExistentSchemeOnlyRoute_ShouldFailWithRouteNotFound() {

        let route = URL(string: "schemeA://")!
        let nonExistentRoute = URL(string: "schemeB://")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(nonExistentRoute)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: partial match

    func testUnregister_WithPartialMatchingRoute_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme://host/path/to")!
        let partialMatchRouteA = URL(string: "scheme:///host/path")!
        let partialMatchRouteB = URL(string: "scheme:///host/path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(partialMatchRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(partialMatchRouteB)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithPartialMatchingRouteAndEmptyHost_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme:///path/to")!
        let partialMatchRouteA = URL(string: "scheme:////path")!
        let partialMatchRouteB = URL(string: "scheme:////path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(partialMatchRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(partialMatchRouteB)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithPartialMatchingRouteAndEmptyScheme_ShouldFailWithRouteNotFound() {

        let route = URL(string: "://host/path/to")!
        let partialMatchRouteA = URL(string: ":///host/path")!
        let partialMatchRouteB = URL(string: ":///host/path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(partialMatchRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(partialMatchRouteB)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithPartialMatchingRouteAndEmptyHostAndEmptyScheme_ShouldFailWithRouteNotFound() {

        let route = URL(string: ":///path/to")!
        let partialMatchRouteA = URL(string: ":////path")!
        let partialMatchRouteB = URL(string: ":////path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(partialMatchRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try router.unregister(partialMatchRouteB)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: success

    func testUnregister_WithMatchingSchemeOnlyRoute_ShouldSucceed() {

        let route = URL(string: "scheme://")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingRouteWithHost_ShouldSucceed() {

        let route = URL(string: "scheme://host")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingRouteWithHostAndEmpty_ShouldSucceed() {

        let route = URL(string: "scheme://host/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingRouteWithHostAndPath_ShouldSucceed() {

        let route = URL(string: "scheme://host/path")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingRouteWithEmptyHost_ShouldSucceed() {

        let route = URL(string: "scheme:///")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingRouteWithEmptyHostAndEmpty_ShouldSucceed() {

        let route = URL(string: "scheme:////")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingRouteWithHostAndPathAndEmpty_ShouldSucceed() {

        let route = URL(string: "scheme://host/path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingRouteWithEmptyHostAndPath_ShouldSucceed() {

        let route = URL(string: "scheme:///path")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingRouteWithEmptyHostAndPathAndEmpty_ShouldSucceed() {

        let route = URL(string: "scheme:///path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeOnlyRoute_ShouldSucceed() {

        let route = URL(string: "://")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeRouteWithHost_ShouldSucceed() {

        let route = URL(string: "://host")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeRouteWithHostAndEmpty_ShouldSucceed() {

        let route = URL(string: "://host/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeRouteWithHostAndPath_ShouldSucceed() {

        let route = URL(string: "://host/path")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeRouteWithEmptyHost_ShouldSucceed() {

        let route = URL(string: ":///")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeRouteWithEmptyHostAndEmpty_ShouldSucceed() {

        let route = URL(string: ":////")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeRouteWithHostAndPathAndEmpty_ShouldSucceed() {

        let route = URL(string: "://host/path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeRouteWithEmptyHostAndPath_ShouldSucceed() {

        let route = URL(string: ":///path")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testUnregister_WithMatchingEmptySchemeRouteWithEmptyHostAndPathAndEmpty_ShouldSucceed() {

        let route = URL(string: ":///path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
        
        do {
            let handler = try router.unregister(route)
            XCTAssert(handler === testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: route

    // MARK: error

    // route not found

    func testRoute_WithNonExistentRouteAndEmptyHost_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme:///path")!
        let invalidRoute = URL(string: "scheme:///non-existent")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(invalidRoute)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRoute_WithNonExistentRouteAndScheme_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme://host/path")!
        do {
            try router.route(route)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRoute_WithNonExistentRouteAndSchemeAndEmptyHost_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme:///path")!
        do {
            try router.route(route)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRoute_WithNonExistentRouteAndExistentScheme_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme://host/path")!
        let nonExistentRoute = URL(string: "scheme://host/non-existent")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(nonExistentRoute)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRoute_WithNonExistentSchemeOnlyRouteAndExistentSchemeOnlyRoute_ShouldFailWithRouteNotFound() {

        let route = URL(string: "schemeA://")!
        let nonExistentRoute = URL(string: "schemeB://")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(nonExistentRoute)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: partial match

    func testRoute_WithPartialMatchingRoute_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme://host/path/to")!
        let partialMatchRouteA = URL(string: "scheme://host/path")!
        let partialMatchRouteB = URL(string: "scheme://host/path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(partialMatchRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(partialMatchRouteB)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRoute_WithPartialMatchingRouteAndEmptyHost_ShouldFailWithRouteNotFound() {

        let route = URL(string: "scheme:///path/to")! // is equivalent to wildcard host (*)
        let partialMatchRouteA = URL(string: "scheme://host/path")!
        let partialMatchRouteB = URL(string: "scheme://host/path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(partialMatchRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(partialMatchRouteB)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRoute_WithPartialMatchingRouteAndEmptyScheme_ShouldFailWithRouteNotFound() {

        let route = URL(string: "://host/path/to")!
        let partialMatchRouteA = URL(string: "://host/path")!
        let partialMatchRouteB = URL(string: "://host/path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(partialMatchRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(partialMatchRouteB)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRoute_WithPartialMatchingRouteAndEmptyHostAndEmptyScheme_ShouldFailWithRouteNotFound() {

        let route = URL(string: ":///path/to")!
        let partialMatchRouteA = URL(string: "://path")!
        let partialMatchRouteB = URL(string: "://path/")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(partialMatchRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(partialMatchRouteB)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // invalid route

    func testRoute_WithVariableComponentInHost_ShouldFailWithInvalidRoute() {

        let route = URL(string: "scheme://host/path/to")!

        let variableComponentA: Route.Component = ":variable"
        let variableComponentB: Route.Component = "*"

        let invalidRouteA = URL(string: "scheme://" + variableComponentA.description + "/path")!
        let invalidRouteB = URL(string: "scheme://" + variableComponentB.description + "/path")!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(invalidRouteA)
            XCTFail("🔥: unexpected success!")
        } catch TestRouter.Error.invalidRoute(.invalidURL) {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(invalidRouteB)
            XCTFail("🔥: unexpected success!")
        } catch let TestRouter.Error.invalidRoute(.invalidVariableComponent(component)) {
            // expected error 💪
            XCTAssertEqual(component, variableComponentB.description)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testRoute_WithVariableComponentInPath_ShouldFailWithInvalidRoute() {

        let route = URL(string: "scheme://host/path/to")!

        let variableComponentA: Route.Component = ":variable"
        let variableComponentB: Route.Component = "*"

        let invalidRouteA = URL(string: "scheme://host/" + variableComponentA.description)!
        let invalidRouteB = URL(string: "scheme://host/" + variableComponentB.description)!

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(invalidRouteA)
            XCTFail("🔥: unexpected success!")
        } catch let TestRouter.Error.invalidRoute(.invalidVariableComponent(component)) {
            // expected error 💪
            XCTAssertEqual(component, variableComponentA.description)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(invalidRouteB)
            XCTFail("🔥: unexpected success!")
        } catch let TestRouter.Error.invalidRoute(.invalidVariableComponent(component)) {
            // expected error 💪
            XCTAssertEqual(component, variableComponentB.description)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: success

    func testRoute_WithMatchingSchemeAndEmptyRoute_ShouldSucceed() {

        let route = URL(string: "scheme://")!

        let expectation = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completion: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, route)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectation.fulfill()
        }

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(route, completion: completion)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectation.fulfill()
        }
    }

    func testRoute_WithMatchingSchemeAndWildcardHost_ShouldSucceed() {

        let route = URL(string: "scheme:///")!

        let expectation = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completion: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, route)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectation.fulfill()
        }

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(route, completion: completion)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectation.fulfill()
        }
    }

    func testRoute_WithMatchingEmptySchemeAndEmptyRoute_ShouldSucceed() {

        let route = URL(string: "://")!

        let expectation = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completion: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, route)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectation.fulfill()
        }

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(route, completion: completion)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectation.fulfill()
        }
    }

    func testRoute_WithMatchingEmptySchemeAndWildcardHost_ShouldSucceed() {

        let route = URL(string: ":///")!

        let expectation = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completion: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, route)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectation.fulfill()
        }

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(route, completion: completion)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectation.fulfill()
        }
    }

    func testRoute_WithMatchingSchemeAndHost_ShouldSucceed() {

        let routeA = URL(string: "scheme://host")!
        let routeB = URL(string: "scheme://host/")! // with terminating empty

        let expectationA = self.expectation(description: "TreeRouter.route")
        let expectationB = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completionA: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeA)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectationA.fulfill()
        }

        do {
            try router.register(routeA, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(routeA, completion: completionA)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationA.fulfill()
        }

        let completionB: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeB)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectationB.fulfill()
        }

        do {
            try router.route(routeB, completion: completionB)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationB.fulfill()
        }
    }

    func testRoute_WithMatchingSchemeHostAndPath_ShouldSucceed() {

        let routeA = URL(string: "scheme://host/path/to/resource")!
        let routeB = URL(string: "scheme://host/path/to/resource/")! // with terminating empty

        let expectationA = self.expectation(description: "TreeRouter.route")
        let expectationB = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completionA: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeA)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectationA.fulfill()
        }

        do {
            try router.register(routeA, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(routeA, completion: completionA)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationA.fulfill()
        }

        let completionB: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeB)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectationB.fulfill()
        }

        do {
            try router.route(routeB, completion: completionB)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationB.fulfill()
        }
    }

    func testRoute_WithMatchingSchemeHostAndEmptyPath_ShouldSucceed() {

        let routeA = URL(string: "scheme://host/")!
        let routeB = URL(string: "scheme://host//")! // with terminating empty

        let expectationA = self.expectation(description: "TreeRouter.route")
        let expectationB = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completionA: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeA)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectationA.fulfill()
        }

        do {
            try router.register(routeA, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(routeA, completion: completionA)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationA.fulfill()
        }

        let completionB: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeB)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectationB.fulfill()
        }

        do {
            try router.route(routeB, completion: completionB)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationB.fulfill()
        }
    }

    func testRoute_WithMatchingSchemeHostAndParameterPath_ShouldSucceedAndPassParametersToHandler() {

        let parameterA = "parameterA"
        let parameterB = "parameterB"

        let parameterValueA = "valueA"
        let parameterValueB = "valueB"

        let route = URL(string: "scheme://host/:\(parameterA)/:\(parameterB)")!

        let routeA = URL(string: "scheme://host/\(parameterValueA)/\(parameterValueB)")!
        let routeB = URL(string: "scheme://host/\(parameterValueA)/\(parameterValueB)/")! // with terminating empty

        let expectationA = self.expectation(description: "TreeRouter.route")
        let expectationB = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completionA: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeA)
            XCTAssertEqual(parameters, [parameterA.description : parameterValueA,
                                        parameterB.description : parameterValueB])
            XCTAssertEqual(queryItems, [])
            expectationA.fulfill()
        }

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(routeA, completion: completionA)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationA.fulfill()
        }

        let completionB: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeB)
            XCTAssertEqual(parameters, [parameterA.description : parameterValueA,
                                        parameterB.description : parameterValueB])
            XCTAssertEqual(queryItems, [])
            expectationB.fulfill()
        }

        do {
            try router.route(routeB, completion: completionB)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationB.fulfill()
        }
    }

    func testRoute_WithMatchingSchemeHostAndWildcardPath_ShouldSucceedAndPassEmptyParametersToHandler() {

        let route = URL(string: "scheme://host/*/*")!

        let routeA = URL(string: "scheme://host/path/to")!
        let routeB = URL(string: "scheme://host/path/to/")! // with terminating empty

        let expectationA = self.expectation(description: "TreeRouter.route")
        let expectationB = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completionA: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeA)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectationA.fulfill()
        }

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(routeA, completion: completionA)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationA.fulfill()
        }

        let completionB: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeB)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, [])
            expectationB.fulfill()
        }

        do {
            try router.route(routeB, completion: completionB)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationB.fulfill()
        }
    }

    func testRoute_WithMatchingSchemeHostAndPathAndQuery_ShouldSucceedAndPassQueryItemsToHandler() {

        let testQueryItems = [URLQueryItem(name: "queryItemA", value: "valueA"),
                              URLQueryItem(name: "queryItemB", value: "valueB")]

        let route = URL(string: "scheme://host/path/to/resource")!

        var routeAComponents = URLComponents(string: "scheme://host/path/to/resource")!
        routeAComponents.queryItems = testQueryItems
        let routeA = routeAComponents.url!

        var routeBComponents = URLComponents(string: "scheme://host/path/to/resource/")! // with terminating empty
        routeBComponents.queryItems = testQueryItems
        let routeB = routeAComponents.url!

        let expectationA = self.expectation(description: "TreeRouter.route")
        let expectationB = self.expectation(description: "TreeRouter.route")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let completionA: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeA)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, testQueryItems)
            expectationA.fulfill()
        }

        do {
            try router.register(route, handler: testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            try router.route(routeA, completion: completionA)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationA.fulfill()
        }

        let completionB: (HandledRoute) -> Void = { url, parameters, queryItems in
            XCTAssertEqual(url, routeB)
            XCTAssertEqual(parameters, [:])
            XCTAssertEqual(queryItems, testQueryItems)
            expectationB.fulfill()
        }

        do {
            try router.route(routeB, completion: completionB)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
            expectationB.fulfill()
        }
    }
}
