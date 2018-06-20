import XCTest
@testable import Alicerce

class Route_Tree_DescriptionTests: XCTestCase {

    typealias TestTree = Route.Tree<String>

    private let testHandler = "test"

    // MARK: - Tree

    // MARK: description

    func testDescription_ShouldMatchValue() {

        do {
            let leafTree = try TestTree(route: [], handler: testHandler)
            guard case .leaf = leafTree else { return XCTFail("🔥: unexpected node type!") }

            XCTAssertEqual(leafTree.description, ".leaf(\(testHandler))")
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        let testComponent = Route.Component(component: "a")
        let testRoute = [testComponent]

        do {
            let nodeTree =  try TestTree(route: testRoute, handler: testHandler)
            guard case let .node(childEdges) = nodeTree else { return XCTFail("🔥: unexpected node type!") }

            XCTAssertEqual(nodeTree.description, ".node(\(childEdges))")
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: debugDescription

    func testDebugDescription_ShouldMatchValue() {

        do {
            let leafTree = try TestTree(route: [], handler: testHandler)
            guard case .leaf = leafTree else { return XCTFail("🔥: unexpected node type!") }

            XCTAssertEqual(leafTree.debugDescription, ".leaf(\(testHandler))")
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }

        let testComponent = Route.Component(component: "a")
        let testRoute = [testComponent]

        do {
            let nodeTree =  try TestTree(route: testRoute, handler: testHandler)
            guard case let .node(childEdges) = nodeTree else { return XCTFail("🔥: unexpected node type!") }

            XCTAssertEqual(nodeTree.debugDescription, ".node(\(childEdges.debugDescription))")
        } catch {
            XCTFail("🔥: unexpected error \(error)!")
        }
    }

    // MARK: - Edge

    // MARK: description

    func testEdgeDescription_ShouldMatchValue() {

        let tree: TestTree
        do {
            tree = try TestTree(route: [], handler: testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        let simple: TestTree.Edge = .simple(tree)
        XCTAssertEqual(simple.description, ".simple(\(tree.description))")

        let parameterName = "parameter"
        let namedParameter: TestTree.Edge = .parameter(parameterName, tree)
        XCTAssertEqual(namedParameter.description, ".parameter(\(parameterName), \(tree.description))")

        let wildcardParameter: TestTree.Edge = .parameter(nil, tree)
        XCTAssertEqual(wildcardParameter.description, ".parameter(*, \(tree.description))")
    }

    // MARK: debugDescription

    func testEdgeDebugDescription_ShouldMatchValue() {

        let tree: TestTree
        do {
            tree = try TestTree(route: [], handler: testHandler)
        } catch {
            return XCTFail("🔥: unexpected error \(error)!")
        }

        let simple: TestTree.Edge = .simple(tree)
        XCTAssertEqual(simple.debugDescription, ".simple(\(tree.debugDescription))")

        let parameterName = "parameter"
        let namedParameter: TestTree.Edge = .parameter(parameterName, tree)
        XCTAssertEqual(namedParameter.debugDescription, ".parameter(\(parameterName), \(tree.debugDescription))")

        let wildcardParameter: TestTree.Edge = .parameter(nil, tree)
        XCTAssertEqual(wildcardParameter.debugDescription, ".parameter(*, \(tree.debugDescription))")
    }
}
