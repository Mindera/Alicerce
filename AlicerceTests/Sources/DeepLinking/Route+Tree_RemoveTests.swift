//
//  Route+Tree_RemoveTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 16/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class Route_Tree_RemoveTests: XCTestCase {

    typealias TestTree = Route.Tree<String>

    let testHandler = "test"

    // MARK: - Error cases

    // MARK: leaf node

    func testRemove_WithRouteContainingFirstEmptyAndOtherComponentsWithEmptyElementOnLeaf_ShouldFailWithRouteNotFound() {

        var testTree: TestTree = .leaf(testHandler)

        do {
            // TODO: perhaps removing an `.empty` from a leaf should behave as an empty route 🤔
            let _ = try testTree.remove(route: [.empty, .constant("a")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .leaf(handler) = testTree, handler == testHandler else {
            return XCTFail("🔥: expected leaf matching handler, got \(testTree)!")
        }
    }

    // MARK: single child node

    func testRemove_WithNonMatchingSingleConstantElementRouteOnSingleConstantChildTree_ShouldFailWithRouteNotFound() {

        let testComponent: Route.Component = .constant("a")
        var testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let nonMatchingComponent: Route.Component = .constant("b")
        let removeRoute = [nonMatchingComponent]

        do {
            let _ = try testTree.remove(route: removeRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
        guard case let .simple(.leaf(handler))? = childEdges[testComponent.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponent.key]))!")
        }

        XCTAssertEqual(handler, testHandler)
    }

    func testRemove_WithNonMatchingSingleValueParameterElementRouteOnSingleVariableChildTree_ShouldReturnFailWithRouteNotFound() {

        let testComponent: Route.Component = .variable(nil)
        var testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let nonMatchingComponent: Route.Component = .variable("a")
        let removeRoute = [nonMatchingComponent]

        do {
            let _ = try testTree.remove(route: removeRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
        guard case let .parameter(parameterName, .leaf(handler))? = childEdges[testComponent.key] else {
            return XCTFail("🔥: expected parameter leaf, got \(String(describing: childEdges[testComponent.key]))!")
        }

        XCTAssertEqual(handler, testHandler)
        XCTAssertNil(parameterName)
    }

    func testRemove_WithNonMatchingSingleValueParameterElementRouteOnSingleEmptyChildTree_ShouldFailWithRouteNotFound() {

        let testComponent: Route.Component = .empty
        var testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        do {
            // test empty vs constant match
            let _ = try testTree.remove(route: [.constant("a")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            // empty vs variable
            let _ = try testTree.remove(route: [.variable("a")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
        guard case let .simple(.leaf(handler))? = childEdges[testComponent.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponent.key]))!")
        }
        
        XCTAssertEqual(handler, testHandler)
    }

    // MARK: multi child node

    func testRemove_WithNonMatchingSingleElementRouteOnMultiChildTree_ShouldFailWithRouteNotFound() {

        let testComponentA: Route.Component = .empty
        let testComponentB: Route.Component = .constant("b")

        let testHandlerA = testHandler
        let testHandlerB = "testB"

        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandlerA)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(testHandlerB))])

        let nonMatchingComponent: Route.Component = .constant("a")
        let removeRoute = [nonMatchingComponent]

        do {
            let _ = try testTree.remove(route: removeRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard case let .simple(.leaf(handlerA))? = childEdges[testComponentA.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .simple(.leaf(handlerB))? = childEdges[testComponentB.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }

        XCTAssertEqual(handlerA, testHandlerA)
        XCTAssertEqual(handlerB, testHandlerB)
    }

    func testRemove_WithNonMatchingRouteOnMultiLevelConstantTree_ShouldFailWithRouteNotFoundAndNotAlterTree() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let nonExistentComponentC: Route.Component = .constant("c")
        let removeRoute = [nonExistentComponentC]

        do {
            let _ = try testTree.remove(route: removeRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard case let .simple(.node(childEdgesA))? = childEdges[testComponentA.key] else {
            return XCTFail("🔥: expected simple node, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .simple(.leaf(existingHandler))? = childEdgesA[testComponentB.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }

        XCTAssertEqual(existingHandler, testHandler)
    }

    // MARK: multi level node

    func testRemove_WithNonMatchingValueParameterRouteOnMultiLevelValueParameteTree_ShouldFailWithRouteNotFoundAndNotAlterTree() {

        let testParameterA = "a"
        let testParameterB = "b"
        let testComponentA: Route.Component = .variable(testParameterA)
        let testComponentB: Route.Component = .variable(testParameterB)

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let nonExistentComponentC: Route.Component = .variable("c")
        let removeRoute = [nonExistentComponentC]

        do {
            let _ = try testTree.remove(route: removeRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard case let .parameter(parameterA, .node(childEdgesA))? = childEdges[testComponentA.key] else {
            return XCTFail("🔥: expected parameter node, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .parameter(parameterB, .leaf(existingHandler))? = childEdgesA[testComponentB.key] else {
            return XCTFail("🔥: expected parameter leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }

        XCTAssertEqual(existingHandler, testHandler)
        XCTAssertEqual(parameterA, testParameterA)
        XCTAssertEqual(parameterB, testParameterB)
    }

    func testRemove_WithNonMatchingWildcardParameterRouteOnMultiLevelValueParameteTree_ShouldFailWithRouteNotFoundAndNotAlterTree() {

        let testParameterA = "a"
        let testParameterB = "b"
        let testComponentA: Route.Component = .variable(testParameterA)
        let testComponentB: Route.Component = .variable(testParameterB)

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let nonExistentComponentC: Route.Component = .variable(nil)
        let removeRoute = [nonExistentComponentC]

        do {
            let _ = try testTree.remove(route: removeRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard case let .parameter(parameterA, .node(childEdgesA))? = childEdges[testComponentA.key] else {
            return XCTFail("🔥: expected parameter node, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .parameter(parameterB, .leaf(existingHandler))? = childEdgesA[testComponentB.key] else {
            return XCTFail("🔥: expected parameter leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }

        XCTAssertEqual(existingHandler, testHandler)
        XCTAssertEqual(parameterA, testParameterA)
        XCTAssertEqual(parameterB, testParameterB)
    }

    func testRemove_WithPartialMatchingRouteOnMultiLevelConstantTree_ShouldFailWithRouteNotFoundAndNotAlterTree() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let nonExistentComponentC: Route.Component = .constant("c")
        let removeRoute = [testComponentA, testComponentB, nonExistentComponentC]

        do {
            let _ = try testTree.remove(route: removeRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard case let .simple(.node(childEdgesA))? = childEdges[testComponentA.key] else {
            return XCTFail("🔥: expected simple node, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .simple(.leaf(existingHandler))? = childEdgesA[testComponentB.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }

        XCTAssertEqual(existingHandler, testHandler)
    }

    func testRemove_WithPartialMatchingRouteAndNonMatchingTreeOnMultiLevelValueParameterTree_ShouldFailWithRouteNotFoundAndNotAlterTree() {

        let testParameterA = "a"
        let testParameterB = "b"

        let testComponentA: Route.Component = .variable(testParameterA)
        let testComponentB: Route.Component = .variable(testParameterB)

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let nonExistentComponentC: Route.Component = .variable("c")
        let removeRoute = [testComponentA, testComponentB, nonExistentComponentC]

        do {
            let _ = try testTree.remove(route: removeRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard case let .parameter(parameterA, .node(childEdgesA))? = childEdges[testComponentA.key] else {
            return XCTFail("🔥: expected parameter node, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .parameter(parameterB, .leaf(existingHandler))? = childEdgesA[testComponentB.key] else {
            return XCTFail("🔥: expected parameter leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }
        
        XCTAssertEqual(existingHandler, testHandler)
        XCTAssertEqual(parameterA, testParameterA)
        XCTAssertEqual(parameterB, testParameterB)
    }

    // MARK: - Success cases

    // MARK: leaf node

    func testRemove_WithEmptyRouteOnLeaf_ShouldReturnHandlerAndChangeLeafToEmptyTree() {

        var testTree: TestTree = .leaf(testHandler)

        do {
            let handler = try testTree.remove(route: [])
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    func testRemove_WithRouteContainingSingleEmptyComponentOnLeaf_ShouldReturnHandlerAndChangeLeafToEmptyTree() {

        var testTree: TestTree = .leaf(testHandler)

        do {
            let handler = try testTree.remove(route: [.empty])
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    // MARK: single child node

    func testRemove_WithMatchingSingleEmptyElementRouteOnSingleChildTree_ShouldReturnHandlerAndChangeToEmptyTree() {

        let testComponent: Route.Component = .empty
        var testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let removeRoute = [testComponent]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    func testRemove_WithMatchingElementAndLastSingleEmptyElementRouteOnSingleChildTree_ShouldReturnHandlerAndChangeToEmptyTree() {

        let testComponent: Route.Component = .constant("a")
        var testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let removeRoute = [testComponent, .empty]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    func testRemove_WithMatchingSingleConstantElementRouteOnSingleChildTree_ShouldReturnHandlerAndChangeToEmptyTree() {

        let testComponent: Route.Component = .constant("a")
        var testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let removeRoute = [testComponent]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    func testRemove_WithMatchingSingleValueParameterElementRouteOnSingleChildTree_ShouldReturnHandlerAndChangeToEmptyTree() {

        let testComponent : Route.Component = .variable("a")
        var testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let removeRoute = [testComponent]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    func testRemove_WithMatchingSingleWildcardParameterElementRouteOnSingleChildTree_ShouldReturnHandlerAndChangeToEmptyTree() {

        let testComponent: Route.Component = .variable(nil)
        var testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let removeRoute = [testComponent]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    // MARK: multi child node

    func testRemove_WithMatchingSingleEmptyElementRouteOnMultiChildTree_ShouldReturnHandlerAndRemoveMatchedTree() {

        let testComponentA: Route.Component = .empty
        let testComponentB: Route.Component = .constant("b")

        let testHandlerA = testHandler
        let testHandlerB = "testB"

        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandlerA)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(testHandlerB))])

        let removeRoute = [testComponentA]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard childEdges[testComponentA.key] == nil else {
            return XCTFail("🔥: expected nil, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .simple(.leaf(handlerB))? = childEdges[testComponentB.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }
        
        XCTAssertEqual(handlerB, testHandlerB)
    }

    func testRemove_WithMatchingSingleConstantElementRouteOnMultiChildTree_ShouldReturnHandlerAndRemoveMatchedTree() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let testHandlerA = testHandler
        let testHandlerB = "testB"

        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandlerA)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(testHandlerB))])

        let removeRoute = [testComponentA]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard childEdges[testComponentA.key] == nil else {
            return XCTFail("🔥: expected nil, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .simple(.leaf(handlerB))? = childEdges[testComponentB.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }

        XCTAssertEqual(handlerB, testHandlerB)
    }

    func testRemove_WithMatchingSingleValueParameterElementRouteOnMultiChildTree_ShouldReturnHandlerAndRemoveMatchedTree() {

        let testParameterA = "a"

        let testComponentA: Route.Component = .variable(testParameterA)
        let testComponentB: Route.Component = .constant("b")

        let testHandlerA = testHandler
        let testHandlerB = "testB"

        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandlerA)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(testHandlerB))])

        let removeRoute = [testComponentA]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard childEdges[testComponentA.key] == nil else {
            return XCTFail("🔥: expected nil, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .simple(.leaf(handlerB))? = childEdges[testComponentB.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }
        
        XCTAssertEqual(handlerB, testHandlerB)
    }

    func testRemove_WithMatchingSingleWildcardParameterElementRouteOnMultiChildTree_ShouldReturnHandlerAndRemoveMatchedTree() {

        let testComponentA: Route.Component = .variable(nil)
        let testComponentB: Route.Component = .constant("b")

        let testHandlerA = testHandler
        let testHandlerB = "testB"

        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandlerA)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(testHandlerB))])

        let removeRoute = [testComponentA]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard childEdges[testComponentA.key] == nil else {
            return XCTFail("🔥: expected nil, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard case let .simple(.leaf(handlerB))? = childEdges[testComponentB.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentB.key]))!")
        }
        
        XCTAssertEqual(handlerB, testHandlerB)
    }

    // MARK: multi level node

    func testRemove_WithPartialMatchingWithFinalEmptyElementRouteOnMultiLevelConstantTree_ShouldReturnHandlerAndRemoveMatchedAndEmptyTrees() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let emptyComponent: Route.Component = .empty
        let removeRoute = [testComponentA, testComponentB, emptyComponent]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    func testRemove_WithPartialMatchingWithFinalEmptyElementRouteOnMultiLevelValueParameterTree_ShouldReturnHandlerAndRemoveMatchedAndEmptyTrees() {

        let testComponentA: Route.Component = .variable("a")
        let testComponentB: Route.Component = .variable("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let emptyComponent: Route.Component = .empty
        let removeRoute = [testComponentA, testComponentB, emptyComponent]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    func testRemove_WithMatchingRouteOnMultiLevelConstantTreeWithNoMoreTrees_ShouldReturnHandlerAndSetEmptyTree() {
        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let removeRoute = [testComponentA, testComponentB]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }

    func testRemove_WithMatchingRouteOnMultiLevelVariableTreeWithNoMoreTrees_ShouldReturnHandlerAndSetEmptyTree() {
        let testComponentA: Route.Component = .variable("a")
        let testComponentB: Route.Component = .variable("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let removeRoute = [testComponentA, testComponentB]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childs) = testTree, childs.isEmpty else {
            return XCTFail("🔥: expected empty node, got \(testTree)!")
        }
    }
    func testRemove_WithMatchingRouteOnMultiLevelConstantTreeWithMoreTrees_ShouldReturnHandlerAndRemoveMatchedAndLeaveNonEmptyTrees() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")
        let testComponentC: Route.Component = .constant("c")

        let testHandlerC = "testC"

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler)),
                                          testComponentC.key : testComponentC.edge(for: .leaf(testHandlerC))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let removeRoute = [testComponentA, testComponentB]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard case let .simple(.node(childEdgesA))? = childEdges[testComponentA.key] else {
            return XCTFail("🔥: expected simple node, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard childEdgesA[testComponentB.key] == nil else {
            return XCTFail("🔥: expected nil, got \(String(describing: childEdgesA[testComponentB.key]))!")
        }
        guard case let .simple(.leaf(handlerC))? = childEdgesA[testComponentC.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentC.key]))!")
        }

        XCTAssertEqual(handlerC, testHandlerC)
    }

    func testRemove_WithMatchingRouteOnMultiLevelVariableTreeWithMoreTrees_ShouldReturnHandlerAndRemoveMatchedAndLeaveNonEmptyTrees() {

        let testParameterA = "a"
        let testParameterB = "b"

        let testComponentA: Route.Component = .variable(testParameterA)
        let testComponentB: Route.Component = .variable(testParameterB)
        let testComponentC: Route.Component = .constant("c")

        let testHandlerC = "testC"

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler)),
                                          testComponentC.key : testComponentC.edge(for: .leaf(testHandlerC))])
        var testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let removeRoute = [testComponentA, testComponentB]

        do {
            let handler = try testTree.remove(route: removeRoute)
            XCTAssertEqual(handler, testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        guard case let .node(childEdges) = testTree else {
            return XCTFail("🔥: expected node, got \(testTree)!")
        }
        guard case let .parameter(parameterA, .node(childEdgesA))? = childEdges[testComponentA.key] else {
            return XCTFail("🔥: expected parameter node, got \(String(describing: childEdges[testComponentA.key]))!")
        }
        guard childEdgesA[testComponentB.key] == nil else {
            return XCTFail("🔥: expected nil, got \(String(describing: childEdgesA[testComponentB.key]))!")
        }
        guard case let .simple(.leaf(handlerC))? = childEdgesA[testComponentC.key] else {
            return XCTFail("🔥: expected simple leaf, got \(String(describing: childEdges[testComponentC.key]))!")
        }

        XCTAssertEqual(handlerC, testHandlerC)
        XCTAssertEqual(parameterA, testParameterA) 
    }
}
