//
//  Route+Tree_MatchTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 16/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class Route_Tree_MatchTests: XCTestCase {

    typealias TestTree = Route.Tree<String>

    let testHandler = "test"

    // MARK: - Error cases

    // MARK: leaf node

    func testMatch_WithNonMatchingRouteContainingNonEmptyElementOnLeaf_ShouldFailWithRouteNotFound() {

        let testTree: TestTree = .leaf(testHandler)

        do {
            let _ = try testTree.match(route: [.constant("a")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try testTree.match(route: [.variable("a")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try testTree.match(route: [.variable(nil)])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithRouteContainingMultipleComponentsOnLeaf_ShouldFailWithRouteNotFound() {

        let testTree: TestTree = .leaf(testHandler)

        do {
            let _ = try testTree.match(route: [.empty, .constant("a")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try testTree.match(route: [.variable(nil), .constant("a")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try testTree.match(route: [.variable("a"), .constant("b")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        do {
            let _ = try testTree.match(route: [.constant("a"), .variable("b")])
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: single child node

    func testMatch_WithRouteWithWildcardParameterComponent_ShouldFailWithInvalidComponent() {

        let testTree: TestTree = .node([.empty : .simple(.leaf(testHandler))])

        let variableComponent: Route.Component = .variable(nil)
        let matchRoute = [variableComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
            XCTFail("🔥: unexpected success!")
        } catch let TestTree.Error.invalidComponent(component) {
            XCTAssertEqual(component, variableComponent)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithRouteWithValueParameterComponentOnSingleEmptyChildTree_ShouldFailWithInvalidComponent() {

        let testTree: TestTree = .node([.empty : .simple(.leaf(testHandler))])

        let variableComponent: Route.Component = .variable("a")
        let matchRoute = [variableComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
            XCTFail("🔥: unexpected success!")
        } catch let TestTree.Error.invalidComponent(component) {
            XCTAssertEqual(component, variableComponent)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithNonMatchingSingleConstantElementRouteOnSingleEmptyChildTree_ShouldFailWithRouteNotFound() {

        let testComponent: Route.Component = .empty
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let nonMatchingComponent: Route.Component = .constant("a")
        let matchRoute = [nonMatchingComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithNonMatchingSingleConstantElementRouteOnSingleConstantChildTree_ShouldFailWithRouteNotFound() {

        let testComponent: Route.Component = .constant("a")
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let nonMatchingComponent: Route.Component = .constant("b")
        let matchRoute = [nonMatchingComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithEmptyElementRouteOnSingleConstantChildTree_ShouldFailWithRouteNotFound() {

        let testComponent: Route.Component = .constant("a")
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let nonMatchingComponent: Route.Component = .empty
        let matchRoute = [nonMatchingComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithEmptyElementRouteOnSingleValueParameterChildTree_ShouldFailWithRouteNotFound() {

        let testComponent: Route.Component = .variable("a")
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let nonMatchingComponent: Route.Component = .empty
        let matchRoute = [nonMatchingComponent]

        do {
            // TODO: evaluate if it makes sense to consider .empty as a valid value parameter
            // e.g.: should "/a/" match "/a/:p"?
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithEmptyElementRouteOnSingleWildcardParameterChildTree_ShouldFailWithRouteNotFound() {

        let testComponent: Route.Component = .variable(nil)
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let nonMatchingComponent: Route.Component = .empty
        let matchRoute = [nonMatchingComponent]

        do {
            // TODO: evaluate if it makes sense to consider .empty as a valid wildcard parameter
            // e.g.: should "/a/" match "/a/*"?
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: multi child node

    func testMatch_WithNonMatchingEmptyElementRouteOnMultiChildTree_ShouldFailWithRouteNotFound() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf("")),
                                        testComponentB.key : testComponentB.edge(for: .leaf(""))])

        let nonMatchingComponent: Route.Component = .empty
        let matchRoute = [nonMatchingComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithNonMatchingSingleConstantElementRouteOnMultiChildTree_ShouldFailWithRouteNotFound() {

        let testComponentA: Route.Component = .empty
        let testComponentB: Route.Component = .constant("a")

        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf("")),
                                        testComponentB.key : testComponentB.edge(for: .leaf(""))])

        let nonMatchingComponent: Route.Component = .constant("b")
        let matchRoute = [nonMatchingComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: multi level node

    func testMatch_WithNonMatchingConstantElementRouteOnMultiLevelChildTreeWithConstantChild_ShouldFailWithRouteNotFoundError() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let nonExistentComponent: Route.Component = .constant("c")

        // non matching
        var matchRoute = [nonExistentComponent]
        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // partial match
        matchRoute = [testComponentA, nonExistentComponent]
        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithNonMatchingConstantElementRouteOnMultiLevelChildTreeWithValueParameterChild_ShouldFailWithRouteNotFoundError() {

        let testComponentA: Route.Component = .variable("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let matchingComponent: Route.Component = .constant("c")
        let nonExistentComponent: Route.Component = .constant("d")
        let matchRoute = [matchingComponent, nonExistentComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithNonMatchingConstantElementRouteOnMultiLevelChildTreeWithWildcardParameterChild_ShouldFailWithRouteNotFoundError() {

        let testComponentA: Route.Component = .variable(nil)
        let testComponentB: Route.Component = .constant("a")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let matchingComponent: Route.Component = .constant("b")
        let nonExistentComponent: Route.Component = .constant("c")
        let matchRoute = [matchingComponent, nonExistentComponent]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithNonMatchingConstantAndEmptyElementRouteOnMultiLevelChildTreeWithConstantChild_ShouldFailWithRouteNotFoundError() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let matchingComponent: Route.Component = .constant("a")
        let matchRoute = [matchingComponent, .empty]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithNonMatchingConstantAndEmptyElementRouteOnMultiLevelChildTreeWithValueParameterChild_ShouldFailWithRouteNotFoundError() {

        let testComponentA: Route.Component = .variable("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let matchingComponent: Route.Component = .constant("a")
        let matchRoute = [matchingComponent, .empty]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithNonMatchingConstantAndEmptyElementRouteOnMultiLevelChildTreeWithWildcardParameterChild_ShouldFailWithRouteNotFoundError() {

        let testComponentA: Route.Component = .variable(nil)
        let testComponentB: Route.Component = .constant("a")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let matchingComponent: Route.Component = .constant("b")
        let matchRoute = [matchingComponent, .empty]

        do {
            let _ = try testTree.match(route: matchRoute)
        } catch TestTree.Error.routeNotFound {
            // expected error 💪
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: - Success cases

    // MARK: leaf node

    func testMatch_WithEmptyRouteOnLeaf_ShouldReturnHandlerAndEmptyParameters() {

        let testTree: TestTree = .leaf(testHandler)

        do {
            let match = try testTree.match(route: [])
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithRouteContainingSingleEmptyComponentOnLeaf_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testTree: TestTree = .leaf(testHandler)

        do {
            let match = try testTree.match(route: [.empty])
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: single child node

    func testMatch_WithMatchingConstantElementRouteOnSingleConstantChildTree_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testComponent: Route.Component = .constant("a")
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let matchRoute = [testComponent]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnValueParameterChildTree_ShouldReturnMatchWithParametersAndHandler() {

        let testParameterName = "a"
        let testComponent: Route.Component = .variable(testParameterName)
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let matchParameterValue = "value"
        let matchComponent: Route.Component = .constant(matchParameterValue)
        let matchRoute = [matchComponent]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterName : matchParameterValue])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnWildcardParameterChildTree_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testComponent: Route.Component = .variable(nil)
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let matchComponent: Route.Component = .constant("a")
        let matchRoute = [matchComponent]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementAndLastSingleEmptyElementRouteOnSingleConstantChildTree_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testComponent: Route.Component = .constant("a")
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let matchRoute = [testComponent, .empty]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementAndLastSingleEmptyElementRouteOnSingleValueParameterChildTree_ShouldReturnMatchWithParameterAndHandler() {

        let testParameterName = "a"
        let testComponent: Route.Component = .variable(testParameterName)
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let matchParameterValue = "value"
        let matchComponent: Route.Component = .constant(matchParameterValue)
        let matchRoute = [matchComponent, .empty]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterName : matchParameterValue])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementAndLastSingleEmptyElementRouteOnWildcardParameterChildTree_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testComponent: Route.Component = .variable(nil)
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        let matchComponent: Route.Component = .constant("a")
        let matchRoute = [matchComponent, .empty]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingEmptyElementAndLastSingleEmptyElementRouteOnEmptyChildTree_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testComponent: Route.Component = .empty
        let testTree: TestTree = .node([testComponent.key : testComponent.edge(for: .leaf(testHandler))])

        do {
            // TODO: evaluate if this makes sense, because it can have an unexpected behaviour on some silly routes:
            // e.g. "/<empty>/<empty>" would match a route for "/<empty>"
            let match = try testTree.match(route: [.empty, .empty])
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: multi child node

    func testMatch_WithMatchingEmptyElementRouteOnMultiChildTreeWithEmptyChild_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .empty
        let testComponentB: Route.Component = .constant("a")

        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandler)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(""))])

        let nonMatchingComponent: Route.Component = .empty
        let matchRoute = [nonMatchingComponent]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiChildTreeWithConstantChild_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .empty

        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandler)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(""))])

        let matchRoute = [testComponentA]

        do {
            let match = try testTree.match(route: matchRoute)

            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiChildTreeWithValueParameterChild_ShouldReturnMatchWithParameterAndHandler() {

        let testParameterA = "a"
        let testComponentA: Route.Component = .variable(testParameterA)
        let testComponentB: Route.Component = .constant("b")

        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandler)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(""))])

        let matchParameterValue = "value"
        let matchComponent: Route.Component = .constant(matchParameterValue)
        let matchRoute = [matchComponent]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterA : matchParameterValue])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiChildTreeWithWildcardParameterChild_ShouldReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .variable(nil)
        let testComponentB: Route.Component = .constant("a")

        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandler)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(""))])

        let matchComponent: Route.Component = .constant("value")
        let matchRoute = [matchComponent]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiChildTreeWithConstantAndValueParameterChild_ShouldMatchConstantAndReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .variable("b")

        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandler)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(""))])

        let matchRoute = [testComponentA]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiChildTreeWithConstantAndWildcardParameterChild_ShouldMatchConstantAndReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .variable(nil)

        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: .leaf(testHandler)),
                                        testComponentB.key : testComponentB.edge(for: .leaf(""))])

        let matchRoute = [testComponentA]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: multi level node

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithConstantChild_ShouldMatchAndReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        // without terminating .empty
        var matchRoute = [testComponentA, testComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [testComponentA, testComponentB, .empty]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithValueParameterChild_ShouldMatchAndReturnMatchWithEmptyParametersAndHandler() {

        let testParameterName = "a"
        let testComponentA: Route.Component = .variable(testParameterName)
        let testComponentB: Route.Component = .constant("b")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let parameterValue = "value"
        let matchingComponent: Route.Component = .constant(parameterValue)

        // without terminating .empty
        var matchRoute = [matchingComponent, testComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterName : parameterValue])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [matchingComponent, testComponentB, .empty]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterName : parameterValue])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithMultiValueParameterChild_ShouldMatchAndReturnMatchWithEmptyParametersAndHandler() {

        let testParameterNameA = "a"
        let testParameterNameB = "b"
        let testComponentA: Route.Component = .variable(testParameterNameA)
        let testComponentB: Route.Component = .variable(testParameterNameB)

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let parameterValueA = "valueA"
        let parameterValueB = "valueB"
        let matchingComponentA: Route.Component = .constant(parameterValueA)
        let matchingComponentB: Route.Component = .constant(parameterValueB)

        // without terminating .empty
        var matchRoute = [matchingComponentA, matchingComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterNameA : parameterValueA,
                                              testParameterNameB : parameterValueB])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [matchingComponentA, matchingComponentB, .empty]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterNameA : parameterValueA,
                                              testParameterNameB : parameterValueB])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithWildcardParameterChild_ShouldMatchAndReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .variable(nil)
        let testComponentB: Route.Component = .constant("a")

        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: .leaf(testHandler))])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let matchingComponent: Route.Component = .constant("b")

        // without terminating .empty
        var matchRoute = [matchingComponent, testComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [matchingComponent, testComponentB, .empty]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithConstantChildAndEmptyLeaf_ShouldMatchAndReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .constant("a")
        let testComponentB: Route.Component = .constant("b")
        let testComponentC: Route.Component = .empty

        let subNestedTree: TestTree = .node([testComponentC.key : testComponentC.edge(for: .leaf(testHandler))])
        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: subNestedTree)])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        // without terminating .empty
        var matchRoute = [testComponentA, testComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [testComponentA, testComponentB, .empty]

        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithSingleValueParameterChildAndEmptyLeaf_ShouldMatchAndReturnMatchWithParametersAndHandler() {

        let testParameterNameA = "a"
        let testComponentA: Route.Component = .variable(testParameterNameA)
        let testComponentB: Route.Component = .constant("b")
        let testComponentC: Route.Component = .empty

        let subNestedTree: TestTree = .node([testComponentC.key : testComponentC.edge(for: .leaf(testHandler))])
        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: subNestedTree)])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let parameterValueA = "valueA"
        let matchingComponentA: Route.Component = .constant(parameterValueA)

        // without terminating .empty
        var matchRoute = [matchingComponentA, testComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterNameA : parameterValueA])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [matchingComponentA, testComponentB, .empty]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterNameA : parameterValueA])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithMultiValueParameterChildAndEmptyLeaf_ShouldMatchAndReturnMatchWithParametersAndHandler() {

        let testParameterNameA = "a"
        let testParameterNameB = "b"
        let testComponentA: Route.Component = .variable(testParameterNameA)
        let testComponentB: Route.Component = .variable(testParameterNameB)
        let testComponentC: Route.Component = .empty

        let subNestedTree: TestTree = .node([testComponentC.key : testComponentC.edge(for: .leaf(testHandler))])
        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: subNestedTree)])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let parameterValueA = "valueA"
        let parameterValueB = "valueB"
        let matchingComponentA: Route.Component = .constant(parameterValueA)
        let matchingComponentB: Route.Component = .constant(parameterValueB)

        // without terminating .empty
        var matchRoute = [matchingComponentA, matchingComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterNameA : parameterValueA,
                                              testParameterNameB : parameterValueB])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [matchingComponentA, matchingComponentB, .empty]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [testParameterNameA : parameterValueA,
                                              testParameterNameB : parameterValueB])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithSingleWildcardParameterChildAndEmptyLeaf_ShouldMatchAndReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .variable(nil)
        let testComponentB: Route.Component = .constant("b")
        let testComponentC: Route.Component = .empty

        let subNestedTree: TestTree = .node([testComponentC.key : testComponentC.edge(for: .leaf(testHandler))])
        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: subNestedTree)])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let matchingComponent: Route.Component = .constant("c")

        // without terminating .empty
        var matchRoute = [matchingComponent, testComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [matchingComponent, testComponentB, .empty]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    func testMatch_WithMatchingConstantElementRouteOnMultiLevelChildTreeWithMultiWildcardParameterChildAndEmptyLeaf_ShouldMatchAndReturnMatchWithEmptyParametersAndHandler() {

        let testComponentA: Route.Component = .variable(nil)
        let testComponentB: Route.Component = .variable(nil)
        let testComponentC: Route.Component = .empty

        let subNestedTree: TestTree = .node([testComponentC.key : testComponentC.edge(for: .leaf(testHandler))])
        let nestedTree: TestTree = .node([testComponentB.key : testComponentB.edge(for: subNestedTree)])
        let testTree: TestTree = .node([testComponentA.key : testComponentA.edge(for: nestedTree)])

        let matchingComponentA: Route.Component = .constant("a")
        let matchingComponentB: Route.Component = .constant("b")

        // without terminating .empty
        var matchRoute = [matchingComponentA, matchingComponentB]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        // with terminating .empty
        matchRoute = [matchingComponentA, matchingComponentB, .empty]
        do {
            let match = try testTree.match(route: matchRoute)
            XCTAssertEqual(match.parameters, [:])
            XCTAssertEqual(match.handler, testHandler)
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }
}

