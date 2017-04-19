//
//  Route+Tree_InitTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 16/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class Route_Tree_InitTests: XCTestCase {

    typealias TestTree = Route.Tree<String>

    let testHandler = "test"

    // MARK: errors

    func testInit_WithRouteWithComponentAfterEmptyElement_ShouldFail() {

        do {
            let _ = try TestTree(route: [.empty, .empty], handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch Route.Tree<String>.Error.invalidRoute {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try TestTree(route: [.empty, .constant("a")], handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch Route.Tree<String>.Error.invalidRoute {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try TestTree(route: [.empty, .variable("a")], handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch Route.Tree<String>.Error.invalidRoute {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try TestTree(route: [.empty, .variable(nil)], handler: testHandler)
            XCTFail("🔥: unexpected success!")
        } catch Route.Tree<String>.Error.invalidRoute {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: success

    // MARK: single level node

    func testInit_WithEmptyRoute_ShouldCreateLeaf() {

        do {
            guard case let .leaf(handler) = try TestTree(route: [], handler: testHandler) else {
                return XCTFail("🔥: unexpected node type!")
            }

            XCTAssertEqual(handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testInit_WithNonEmptyRouteAndEmptyComponent_ShouldCreateLeaf() {

        let testComponent = Route.Component(component: "")
        let testRoute = [testComponent]

        do {
            guard case let .leaf(handler) = try TestTree(route: testRoute, handler: testHandler) else {
                return XCTFail("🔥: unexpected node type!")
            }

            XCTAssertEqual(handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testInit_WithNonEmptyRouteAndConstantComponent_ShouldCreateTreeWithSimpleEdge() {

        let testComponent = Route.Component(component: "a")
        let testRoute = [testComponent]

        do {
            guard case let .node(childEdges) = try TestTree(route: testRoute, handler: testHandler) else {
                return XCTFail("🔥: unexpected node type!")
            }
            guard case let .simple(.leaf(handler))? = childEdges[testComponent.key] else {
                return XCTFail("🔥: unexpected child A edge!")
            }

            XCTAssertEqual(handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testInit_WithNonEmptyRouteAndWildcardVariableComponent_ShouldCreateTreeWithSimpleEdge() {

        let testComponent = Route.Component(component: "*")
        let testRoute = [testComponent]

        do {
            guard case let .node(childEdges) = try TestTree(route: testRoute, handler: testHandler) else {
                return XCTFail("🔥: unexpected node type!")
            }
            guard case let .parameter(nil, .leaf(handler))? = childEdges[testComponent.key] else {
                return XCTFail("🔥: unexpected child A edge!")
            }

            XCTAssertEqual(handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testInit_WithNonEmptyRouteAndParameterVariableComponent_ShouldCreateTreeWithParameterEdge() {

        let testParameterName = "a"
        let testComponent = Route.Component(component: ":" + testParameterName)
        let testRoute = [testComponent]

        do {
            guard case let .node(childEdges) = try TestTree(route: testRoute, handler: testHandler) else {
                return XCTFail("🔥: unexpected node type!")
            }
            guard case let .parameter(parameterName, .leaf(handler))? = childEdges[testComponent.key] else {
                return XCTFail("🔥: unexpected child A edge!")
            }

            XCTAssertEqual(parameterName, testParameterName)
            XCTAssertEqual(handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: multi level node

    func testInit_WithNonEmptyRouteAndConstantComponents_ShouldCreateTreesWithSimpleEdges() {

        let componentA = Route.Component(component: "a")
        let componentB = Route.Component(component: "b")
        let componentC = Route.Component(component: "c")

        let testRoute = [componentA, componentB, componentC]

        do {
            guard case let .node(childEdges) = try TestTree(route: testRoute, handler: testHandler) else {
                return XCTFail("🔥: unexpected node type!")
            }
            guard case let .simple(.node(nodeAChildEdges))? = childEdges[componentA.key] else {
                return XCTFail("🔥: unexpected child A edge!")
            }
            guard case let .simple(.node(nodeBChildEdges))? = nodeAChildEdges[componentB.key] else {
                return XCTFail("🔥: unexpected child B edge!")
            }
            guard case let .simple(.leaf(handler))? = nodeBChildEdges[componentC.key] else {
                return XCTFail("🔥: unexpected child C edge!")
            }

            XCTAssertEqual(handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testInit_WithNonEmptyRouteAndParameterVariableComponents_ShouldCreateTreesWithParameterEdges() {

        let parameterA = "a"
        let parameterB = "b"
        let parameterC = "c"

        let componentA = Route.Component(component: ":" + parameterA)
        let componentB = Route.Component(component: ":" + parameterB)
        let componentC = Route.Component(component: ":" + parameterC)

        let testRoute = [componentA, componentB, componentC]

        do {
            guard case let .node(childEdges) = try TestTree(route: testRoute, handler: testHandler) else {
                return XCTFail("🔥: unexpected node type!")
            }
            guard case let .parameter(parameterAName, .node(nodeAChildEdges))? = childEdges[componentA.key] else {
                return XCTFail("🔥: unexpected child A edge!")
            }
            guard case let .parameter(parameterBName, .node(nodeBChildEdges))? = nodeAChildEdges[componentB.key] else {
                return XCTFail("🔥: unexpected child B edge!")
            }
            guard case let .parameter(parameterCName, .leaf(handler))? = nodeBChildEdges[componentC.key] else {
                return XCTFail("🔥: unexpected child C edge!")
            }

            XCTAssertEqual(parameterAName, parameterA)
            XCTAssertEqual(parameterBName, parameterB)
            XCTAssertEqual(parameterCName, parameterC)
            XCTAssertEqual(handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testInit_WithNonEmptyRouteAndWildcardVariableComponents_ShouldCreateTreesWithNilParameterEdges() {

        let componentA = Route.Component(component: "*")
        let componentB = Route.Component(component: "*")
        let componentC = Route.Component(component: "*")

        let testRoute = [componentA, componentB, componentC]

        do {
            guard case let .node(childEdges) = try TestTree(route: testRoute, handler: testHandler) else {
                return XCTFail("🔥: unexpected node type!")
            }
            guard case let .parameter(nil, .node(nodeAChildEdges))? = childEdges[componentA.key] else {
                return XCTFail("🔥: unexpected child A edge!")
            }
            guard case let .parameter(nil, .node(nodeBChildEdges))? = nodeAChildEdges[componentB.key] else {
                return XCTFail("🔥: unexpected child B edge!")
            }
            guard case let .parameter(nil, .leaf(handler))? = nodeBChildEdges[componentC.key] else {
                return XCTFail("🔥: unexpected child C edge!")
            }
            XCTAssertEqual(handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }
}
