//
//  Route+ComponentTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class Route_ComponentTests: XCTestCase {

    // MARK: init
    
    func testInit_WithEmptyString_ShouldCreateEmptyComponent() {

        let testValue = ""
        guard case .empty = Route.Component(component:testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case .empty = Route.Component(stringLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case .empty = Route.Component(extendedGraphemeClusterLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case .empty = Route.Component(unicodeScalarLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
    }

    func testInit_WithConstantString_ShouldCreateConstantComponent() {

        let testValue = "test"
        guard case let .constant(valueA) = Route.Component(component:testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .constant(valueB) = Route.Component(stringLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .constant(valueC) = Route.Component(extendedGraphemeClusterLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .constant(valueD) = Route.Component(unicodeScalarLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }

        XCTAssertEqual(valueA, testValue)
        XCTAssertEqual(valueB, testValue)
        XCTAssertEqual(valueC, testValue)
        XCTAssertEqual(valueD, testValue)
    }

    func testInit_WithParameterString_ShouldCreateVariableComponentWithMatchingParameterName() {

        let testParameterName = "test"
        let testValue = ":" + testParameterName
        guard case let .variable(parameterNameA) = Route.Component(component:testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .variable(parameterNameB) = Route.Component(stringLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .variable(parameterNameC) = Route.Component(extendedGraphemeClusterLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .variable(parameterNameD) = Route.Component(unicodeScalarLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }

        XCTAssertEqual(parameterNameA, testParameterName)
        XCTAssertEqual(parameterNameB, testParameterName)
        XCTAssertEqual(parameterNameC, testParameterName)
        XCTAssertEqual(parameterNameD, testParameterName)
    }

    func testInit_WithWildcardString_ShouldCreateVariableComponentWithNilParameterName() {

        let testValue = "*"
        guard case let .variable(parameterNameA) = Route.Component(component:testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .variable(parameterNameB) = Route.Component(stringLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .variable(parameterNameC) = Route.Component(extendedGraphemeClusterLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }
        guard case let .variable(parameterNameD) = Route.Component(unicodeScalarLiteral: testValue) else {
            return XCTFail("🔥: unexpected component!")
        }

        XCTAssertNil(parameterNameA)
        XCTAssertNil(parameterNameB)
        XCTAssertNil(parameterNameC)
        XCTAssertNil(parameterNameD)
    }

    // MARK: key

    func testKey_WithEmptyComponent_ShouldReturnEmptyKey() {

        let testComponent: Route.Component = ""

        guard case .empty = testComponent.key else {
            return XCTFail("🔥: unexpected key!")
        }
    }

    func testKey_WithConstantComponent_ShouldReturnConstantKey() {

        let testConstantName = "constant"
        let testComponent = Route.Component(component:testConstantName)

        guard case let .constant(value) = testComponent.key else {
            return XCTFail("🔥: unexpected key!")
        }

        XCTAssertEqual(value, testConstantName)
    }

    func testKey_WithVariableComponent_ShouldReturnVariableKey() {

        var testComponent: Route.Component = ":variable"

        guard case .variable = testComponent.key else {
            return XCTFail("🔥: unexpected key!")
        }

        testComponent = "*"

        guard case .variable = testComponent.key else {
            return XCTFail("🔥: unexpected key!")
        }
    }

    // MARK: edge

    func testEdge_WithEmptyComponent_ShouldReturnSimpleEdge() {

        let testHandler: String = "test"
        let testTree: Route.Tree<String> = .leaf(testHandler)
        let testComponent: Route.Component = ""

        guard case let .simple(.leaf(handler)) = testComponent.edge(for: testTree) else {
            return XCTFail("🔥: unexpected edge!")
        }

        XCTAssertEqual(handler, testHandler)
    }

    func testEdge_WithConstantComponent_ShouldReturnSimpleEdge() {

        let testHandler: String = "test"
        let testTree: Route.Tree<String> = .leaf(testHandler)
        let testComponent: Route.Component = "constant"

        guard case let .simple(.leaf(handler)) = testComponent.edge(for: testTree) else {
            return XCTFail("🔥: unexpected edge!")
        }

        XCTAssertEqual(handler, testHandler)
    }

    func testEdge_WithValueVariableComponent_ShouldReturnVariableEdgeWithMatchingParameter() {

        let testHandler: String = "test"
        let testTree: Route.Tree<String> = .leaf(testHandler)
        let testParameterName = "parameter"
        let testComponent = Route.Component(component:":" + testParameterName)

        guard case let .parameter(parameterName, .leaf(handler)) = testComponent.edge(for: testTree) else {
            return XCTFail("🔥: unexpected edge!")
        }

        XCTAssertEqual(handler, testHandler)
        XCTAssertEqual(parameterName, testParameterName)
    }

    func testEdge_WithWildcardVariableComponent_ShouldReturnVariableEdgeWithNilParameter() {

        let testHandler: String = "test"
        let testTree: Route.Tree<String> = .leaf(testHandler)
        let testComponent: Route.Component = "*"

        guard case let .parameter(parameterName, .leaf(handler)) = testComponent.edge(for: testTree) else {
            return XCTFail("🔥: unexpected edge!")
        }

        XCTAssertEqual(handler, testHandler)
        XCTAssertNil(parameterName)
    }

    // MARK: description

    func testDescription_ShouldMatchValue() {

        let empty: Route.Component = ""
        XCTAssertEqual(empty.description, "")

        let constant: Route.Component = "constant"
        XCTAssertEqual(constant.description, "constant")

        let valueVariable: Route.Component = ":variable"
        XCTAssertEqual(valueVariable.description, ":variable")

        let wildcardVariable: Route.Component = "*"
        XCTAssertEqual(wildcardVariable.description, "*")
    }

    // MARK: debugDescription

    func testDebugDescription_ShouldMatchValue() {

        let empty: Route.Component = ""
        XCTAssertEqual(empty.debugDescription, ".empty")

        let constant: Route.Component = "constant"
        XCTAssertEqual(constant.debugDescription, ".constant(constant)")

        let valueVariable: Route.Component = ":variable"
        XCTAssertEqual(valueVariable.debugDescription, ".variable(variable)")

        let wildcardVariable: Route.Component = "*"
        XCTAssertEqual(wildcardVariable.debugDescription, ".variable(*)")
    }

    // MARK: hashValue

    func testHashValue_ShouldMatchSameValues() {

        let empty: Route.Component = ""
        let empty2: Route.Component = ""

        let constant: Route.Component = "constant"
        let constant2: Route.Component = "constant"

        let valueVariable: Route.Component = ":variable"
        let valueVariable2: Route.Component = ":variable"

        let wildcardVariable: Route.Component = "*"
        let wildcardVariable2: Route.Component = "*"

        XCTAssertEqual(empty.hashValue, empty2.hashValue)
        XCTAssertEqual(constant.hashValue, constant2.hashValue)
        XCTAssertEqual(valueVariable.hashValue, valueVariable2.hashValue)
        XCTAssertEqual(wildcardVariable.hashValue, wildcardVariable2.hashValue)
    }

    func testHashValue_ShouldNotMatchDifferentValues() {

        let empty: Route.Component = ""

        let constant: Route.Component = "constant"
        let constant2: Route.Component = "constant2"

        let valueVariable: Route.Component = ":variable"
        let valueVariable2: Route.Component = ":variable2"

        let wildcardVariable: Route.Component = "*"

        XCTAssertNotEqual(empty.hashValue, constant.hashValue)
        XCTAssertNotEqual(empty.hashValue, valueVariable.hashValue)
        XCTAssertNotEqual(empty.hashValue, wildcardVariable.hashValue)

        XCTAssertNotEqual(constant.hashValue, constant2.hashValue)
        XCTAssertNotEqual(constant.hashValue, valueVariable.hashValue)
        XCTAssertNotEqual(constant.hashValue, wildcardVariable.hashValue)

        XCTAssertNotEqual(valueVariable.hashValue, valueVariable2.hashValue)
        XCTAssertNotEqual(valueVariable.hashValue, wildcardVariable.hashValue)
    }

    // MARK: ==

    func testEquals_ShouldMatchSameValues() {

        let empty: Route.Component = ""
        let constant: Route.Component = "constant"
        let valueVariable: Route.Component = ":variable"
        let wildcardVariable: Route.Component = "*"

        XCTAssertEqual(empty, empty)
        XCTAssertEqual(constant, constant)
        XCTAssertEqual(valueVariable, valueVariable)
        XCTAssertEqual(wildcardVariable, wildcardVariable)
    }

    func testEquals_ShouldNotMatchDifferentValues() {

        let empty: Route.Component = ""
        let constant: Route.Component = "constant"
        let constant2: Route.Component = "constant2"
        let valueVariable: Route.Component = ":variable"
        let valueVariable2: Route.Component = ":variable2"
        let wildcardVariable: Route.Component = "*"

        XCTAssertNotEqual(empty, constant)
        XCTAssertNotEqual(empty, valueVariable)
        XCTAssertNotEqual(empty, wildcardVariable)

        XCTAssertNotEqual(constant, constant2)
        XCTAssertNotEqual(constant, valueVariable)
        XCTAssertNotEqual(constant, wildcardVariable)

        XCTAssertNotEqual(valueVariable, valueVariable2)
        XCTAssertNotEqual(valueVariable, wildcardVariable)
    }

    // MARK: - Key

    func testKeyHashValue_ShouldMatchSameValues() {

        let empty: Route.Component.Key = .empty
        let empty2: Route.Component.Key = .empty
        let constant: Route.Component.Key = .constant("constant")
        let constant2: Route.Component.Key = .constant("constant")
        let variable: Route.Component.Key = .variable
        let variable2: Route.Component.Key = .variable

        XCTAssertEqual(empty.hashValue, empty2.hashValue)
        XCTAssertEqual(constant.hashValue, constant2.hashValue)
        XCTAssertEqual(variable.hashValue, variable2.hashValue)
    }

    func testKeyHashValue_ShouldNotMatchDifferentValues() {

        let empty: Route.Component.Key = .empty
        let constant: Route.Component.Key = .constant("constant")
        let constant2: Route.Component.Key = .constant("constant2")
        let variable: Route.Component.Key = .variable

        XCTAssertNotEqual(empty.hashValue, constant.hashValue)
        XCTAssertNotEqual(empty.hashValue, variable.hashValue)

        XCTAssertNotEqual(constant.hashValue, constant2.hashValue)
        XCTAssertNotEqual(constant.hashValue, variable.hashValue)
    }

    // MARK: ==

    func testKeyEquals_ShouldMatchSameValues() {

        let empty: Route.Component.Key = .empty
        let constant: Route.Component.Key = .constant("constant")
        let variable: Route.Component.Key = .variable

        XCTAssertEqual(empty, empty)
        XCTAssertEqual(constant, constant)
        XCTAssertEqual(variable, variable)
    }

    func testKeyEquals_ShouldNotMatchDifferentValues() {

        let empty: Route.Component.Key = .empty
        let constant: Route.Component.Key = .constant("constant")
        let constant2: Route.Component.Key = .constant("constant2")
        let variable: Route.Component.Key = .variable

        XCTAssertNotEqual(empty, constant)
        XCTAssertNotEqual(empty, variable)

        XCTAssertNotEqual(constant, constant2)
        XCTAssertNotEqual(constant, variable)
    }

    // MARK: description

    func testKeyDescription_ShouldMatchValue() {

        let empty: Route.Component.Key = .empty
        XCTAssertEqual(empty.description, ".empty")

        let constantName = "constant"
        let constant: Route.Component.Key = .constant(constantName)
        XCTAssertEqual(constant.description, ".constant(\(constantName))")

        let valueVariable: Route.Component.Key = .variable
        XCTAssertEqual(valueVariable.description, ".variable")
    }

    // MARK: debugDescription

    func testKeyDebugDescription_ShouldMatchValue() {

        let empty: Route.Component.Key = .empty
        XCTAssertEqual(empty.debugDescription, ".empty")

        let constantName = "constant"
        let constant: Route.Component.Key = .constant(constantName)
        XCTAssertEqual(constant.debugDescription, ".constant(\(constantName))")

        let valueVariable: Route.Component.Key = .variable
        XCTAssertEqual(valueVariable.debugDescription, ".variable")
    }
}
