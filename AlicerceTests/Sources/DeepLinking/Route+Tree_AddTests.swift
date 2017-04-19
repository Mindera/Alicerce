//
//  Route+Tree_AddTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 16/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class Route_Tree_AddTests: XCTestCase {
    
    typealias TestTree = Route.Tree<String>

    let testHandler = "test"

    // MARK: - Error cases

    func testAdd_WithEmptyRouteOnLeaf_ShouldFail() {

        var testTree: TestTree = .leaf(testHandler)

        do {
            try testTree.add(route: [], handler: "💥")
            XCTFail("🔥: unexpected success!")
        } catch TestTree.Error.duplicateEmptyComponent {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testAdd_WithEmptyRouteOnTree_ShouldFail() {

        var testTree: TestTree = .node([.empty : .simple(.leaf(testHandler))])

        do {
            try testTree.add(route: [], handler: "💥")
            XCTFail("🔥: unexpected success!")
        } catch TestTree.Error.duplicateEmptyComponent {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testAdd_WithEmptyComponentRouteOnLeaf_ShouldFail() {

        var testTree: TestTree = .leaf(testHandler)

        do {
            try testTree.add(route: [.empty], handler: "💥")
            XCTFail("🔥: unexpected success!")
        } catch TestTree.Error.duplicateEmptyComponent {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testAdd_WithEmptyComponentRouteOnTreeWithEmptyChildEdge_ShouldFail() {

        var testTree: TestTree = .node([.empty : .simple(.leaf(testHandler))])

        do {
            try testTree.add(route: [.empty], handler: "💥")
            XCTFail("🔥: unexpected success!")
        } catch TestTree.Error.duplicateEmptyComponent {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testAdd_WithParameterVariableComponentRouteOnTreeWithVariableParameterChildEdgeWithConflictingName_ShouldFail() {

        let testParameterName = "testParameterName"
        var testTree: TestTree = .node([.variable : .parameter(testParameterName, .leaf(testHandler))])

        let newParameterName = "newParameterName"
        let newComponent = Route.Component(component: ":" + newParameterName)

        do {
            try testTree.add(route: [newComponent], handler: "💥")
            XCTFail("🔥: unexpected success!")
        } catch let TestTree.Error.conflictingParameterName(existing, new) {
            XCTAssertEqual(existing, testParameterName)
            XCTAssertEqual(new, newParameterName)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testAdd_WithWildcardVariableComponentRouteOnTreeWithVariableParameterChildEdge_ShouldFail() {

        let testParameterName = "testParameterName"
        var testTree: TestTree = .node([.variable : .parameter(testParameterName, .leaf(testHandler))])

        let newComponent = Route.Component(component: "*")

        do {
            try testTree.add(route: [newComponent], handler: "💥")
            XCTFail("🔥: unexpected success!")
        } catch let TestTree.Error.conflictingParameterName(existing, new) {
            XCTAssertEqual(existing, testParameterName)
            XCTAssertEqual(new, "*")
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testAdd_WithParameterVariableComponentRouteOnTreeWithWildcardVariableParameterChildEdge_ShouldFail() {

        var testTree: TestTree = .node([.variable : .parameter(nil, .leaf(testHandler))])

        let newParameterName = "newParameterName"
        let newComponent = Route.Component(component: ":" + newParameterName)

        do {
            try testTree.add(route: [newComponent], handler: "💥")
            XCTFail("🔥: unexpected success!")
        } catch let TestTree.Error.conflictingParameterName(existing, new) {
            XCTAssertEqual(existing, "*")
            XCTAssertEqual(new, newParameterName)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: - Success cases

    // MARK: on leaf

    func testAdd_WithSingleComponentRouteOnLeaf_ShouldUpdateLeafToTreeWithNewRouteLeafAndEmptyLeaf() {

        var testTree: TestTree = .leaf(testHandler)

        let newHandler = "newHandler"
        let newComponent = Route.Component(component: "a")
        let newRoute = [newComponent]

        do {
            try testTree.add(route: newRoute, handler: newHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(newChildEdges) = testTree else {
            return XCTFail("🔥: unexpected node type!")
        }
        guard case let .simple(.leaf(emptyLeafHandler))? = newChildEdges[.empty] else {
            return XCTFail("🔥: unexpected empty child edge!")
        }
        guard case let .simple(.leaf(handler))? = newChildEdges[newComponent.key] else {
            return XCTFail("🔥: unexpected new child edge!")
        }

        XCTAssertEqual(emptyLeafHandler, testHandler)
        XCTAssertEqual(handler, newHandler)
    }

    func testAdd_WithMultiComponentRouteOnLeaf_ShouldUpdateLeafToTreeWithNewRouteTreesAndLastComponentLeafAndEmptyLeaf() {

        var testTree: TestTree = .leaf(testHandler)

        let newHandler = "newHandler"
        let newComponentA = Route.Component(component: "a")
        let newComponentB = Route.Component(component: "b")
        let newRoute = [newComponentA, newComponentB]

        do {
            try testTree.add(route: newRoute, handler: newHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(newChildEdges) = testTree else {
            return XCTFail("🔥: unexpected node type!")
        }
        guard case let .simple(.leaf(emptyLeafHandler))? = newChildEdges[.empty] else {
            return XCTFail("🔥: unexpected empty child edge!")
        }
        guard case let .simple(.node(newChildEdgesA))? = newChildEdges[newComponentA.key] else {
            return XCTFail("🔥: unexpected new child A edge!")
        }
        guard case let .simple(.leaf(handler))? = newChildEdgesA[newComponentB.key] else {
            return XCTFail("🔥: unexpected new child B edge!")
        }

        XCTAssertEqual(emptyLeafHandler, testHandler)
        XCTAssertEqual(handler, newHandler)
    }

    // MARK: on single child node

    func testAdd_WithSingleComponentRouteOnTree_ShouldUpdateTreeWithNewRouteLeaf() {

        var testTree: TestTree = .node([.empty : .simple(.leaf(testHandler))])

        let newHandler = "newHandler"
        let newComponent = Route.Component(component: "a")
        let newRoute = [newComponent]

        do {
            try testTree.add(route: newRoute, handler: newHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(newChildEdges) = testTree else {
            return XCTFail("🔥: unexpected node type!")
        }
        guard case let .simple(.leaf(emptyLeafHandler))? = newChildEdges[.empty] else {
            return XCTFail("🔥: unexpected empty child edge!")
        }
        guard case let .simple(.leaf(handler))? = newChildEdges[newComponent.key] else {
            return XCTFail("🔥: unexpected new child edge!")
        }

        XCTAssertEqual(emptyLeafHandler, testHandler)
        XCTAssertEqual(handler, newHandler)
    }

    func testAdd_WithMultiComponentRouteOnTree_ShouldUpdateTreeWithNewRouteTreesAndLastComponentLeaf() {

        var testTree: TestTree = .node([.empty : .simple(.leaf(testHandler))])

        let newHandler = "newHandler"
        let newComponentA = Route.Component(component: "a")
        let newComponentB = Route.Component(component: "b")
        let newRoute = [newComponentA, newComponentB]

        do {
            try testTree.add(route: newRoute, handler: newHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(newChildEdges) = testTree else {
            return XCTFail("🔥: unexpected node type!")
        }
        guard case let .simple(.leaf(emptyLeafHandler))? = newChildEdges[.empty] else {
            return XCTFail("🔥: unexpected empty child edge!")
        }
        guard case let .simple(.node(newChildEdgesA))? = newChildEdges[newComponentA.key] else {
            return XCTFail("🔥: unexpected new child A edge!")
        }
        guard case let .simple(.leaf(handler))? = newChildEdgesA[newComponentB.key] else {
            return XCTFail("🔥: unexpected new child B edge!")
        }

        XCTAssertEqual(emptyLeafHandler, testHandler)
        XCTAssertEqual(handler, newHandler)
    }

    func testAdd_WithMultiComponentRouteOnTreeMatchingSimpleExistingLeaf_ShouldUpdateTreeWithNewRouteTreesMakeEmptyLeafAndLastComponentLeaf() {

        var testTree: TestTree = .node([.constant("a") : .simple(.leaf(testHandler))])

        let newHandler = "newHandler"
        let newComponentA = Route.Component(component: "a")
        let newComponentB = Route.Component(component: "b")
        let newRoute = [newComponentA, newComponentB]

        do {
            try testTree.add(route: newRoute, handler: newHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(newChildEdges) = testTree else {
            return XCTFail("🔥: unexpected node type!")
        }
        guard case let .simple(.node(newChildEdgesA))? = newChildEdges[newComponentA.key] else {
            return XCTFail("🔥: unexpected child A edge!")
        }
        guard case let .simple(.leaf(existingHandler))? = newChildEdgesA[.empty] else {
            return XCTFail("🔥: unexpected existing child A empty edge!")
        }
        guard case let .simple(.leaf(handler))? = newChildEdgesA[newComponentB.key] else {
            return XCTFail("🔥: unexpected new child A B edge!")
        }

        XCTAssertEqual(existingHandler, testHandler)
        XCTAssertEqual(handler, newHandler)
    }

    func testAdd_WithMultiComponentRouteOnTreeMatchingVariableExistingLeaf_ShouldUpdateTreeWithNewRouteTreesMakeEmptyLeafAndLastComponentLeaf() {

        let testParameterName = "a"
        var testTree: TestTree = .node([.variable : .parameter(testParameterName, .leaf(testHandler))])

        let newHandler = "newHandler"
        let newComponentA = Route.Component(component: ":" + testParameterName)
        let newComponentB = Route.Component(component: "b")
        let newRoute = [newComponentA, newComponentB]

        do {
            try testTree.add(route: newRoute, handler: newHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(newChildEdges) = testTree else {
            return XCTFail("🔥: unexpected node type!")
        }
        guard case let .parameter(parameterName, .node(newChildEdgesA))? = newChildEdges[newComponentA.key] else {
            return XCTFail("🔥: unexpected child A edge!")
        }
        guard case let .simple(.leaf(existingHandler))? = newChildEdgesA[.empty] else {
            return XCTFail("🔥: unexpected existing child A empty edge!")
        }
        guard case let .simple(.leaf(handler))? = newChildEdgesA[newComponentB.key] else {
            return XCTFail("🔥: unexpected new child A B edge!")
        }

        XCTAssertEqual(parameterName, testParameterName)
        XCTAssertEqual(existingHandler, testHandler)
        XCTAssertEqual(handler, newHandler)
    }

    // MARK: on multi child node

    func testAdd_WithNonEmptyMultiComponentRouteOnTreeMatchingSimpleExistingTree_ShouldUpdateTreeWithNewRouteTreesMakeEmptyLeafAndLastComponentLeaf() {

        let nestedTree: TestTree = .node([.constant("b") : .simple(.leaf(testHandler))])
        var testTree: TestTree = .node([.constant("a") : .simple(nestedTree)])

        let newHandler = "newHandler"
        let newComponentA = Route.Component(component: "a")
        let newComponentB = Route.Component(component: "b")
        let newComponentC = Route.Component(component: "c")
        let newRoute = [newComponentA, newComponentB, newComponentC]

        do {
            try testTree.add(route: newRoute, handler: newHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(newChildEdges) = testTree else {
            return XCTFail("🔥: unexpected node type!")
        }
        guard case let .simple(.node(newChildEdgesA))? = newChildEdges[newComponentA.key] else {
            return XCTFail("🔥: unexpected child A edge!")
        }
        guard case let .simple(.node(newChildEdgesB))? = newChildEdgesA[newComponentB.key] else {
            return XCTFail("🔥: unexpected child B edge!")
        }
        guard case let .simple(.leaf(existingHandler))? = newChildEdgesB[.empty] else {
            return XCTFail("🔥: unexpected existing child B empty edge!")
        }
        guard case let .simple(.leaf(handler))? = newChildEdgesB[newComponentC.key] else {
            return XCTFail("🔥: unexpected new child B C edge!")
        }

        XCTAssertEqual(existingHandler, testHandler)
        XCTAssertEqual(handler, newHandler)
    }

    func testAdd_WithNonEmptyMultiComponentRouteOnTreeMatchingVariableExistingTree_ShouldUpdateTreeWithNewRouteTreesMakeEmptyLeafAndLastComponentLeaf() {

        let testParameterNameA = "a"
        let testParameterNameB = "b"

        let nestedTree: TestTree = .node([.variable : .parameter(testParameterNameB, .leaf(testHandler))])
        var testTree: TestTree = .node([.variable : .parameter(testParameterNameA, nestedTree)])

        let newHandler = "newHandler"
        let newComponentA = Route.Component(component: ":" + testParameterNameA)
        let newComponentB = Route.Component(component: ":" + testParameterNameB)
        let newComponentC = Route.Component(component: "c")
        let newRoute = [newComponentA, newComponentB, newComponentC]

        do {
            try testTree.add(route: newRoute, handler: newHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(newChildEdges) = testTree else {
            return XCTFail("🔥: unexpected node type!")
        }
        guard case let .parameter(parameterNameA, .node(newChildEdgesA))? = newChildEdges[newComponentA.key] else {
            return XCTFail("🔥: unexpected child A edge!")
        }
        guard case let .parameter(parameterNameB, .node(newChildEdgesB))? = newChildEdgesA[newComponentB.key] else {
            return XCTFail("🔥: unexpected child A B edge!")
        }
        guard case let .simple(.leaf(existingHandler))? = newChildEdgesB[.empty] else {
            return XCTFail("🔥: unexpected existing child B empty edge!")
        }
        guard case let .simple(.leaf(handler))? = newChildEdgesB[newComponentC.key] else {
            return XCTFail("🔥: unexpected new child B C edge!")
        }
        
        XCTAssertEqual(parameterNameA, testParameterNameA)
        XCTAssertEqual(parameterNameB, testParameterNameB)
        XCTAssertEqual(existingHandler, testHandler)
        XCTAssertEqual(handler, newHandler)
    }
}
