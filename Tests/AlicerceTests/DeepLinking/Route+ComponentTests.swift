import XCTest
@testable import Alicerce

class Route_ComponentTests: XCTestCase {

    // MARK: init

    func testInit_ShouldCreateCorrectComponent() {

        XCTAssertEqual(Route.Component(component: "test"), .constant("test"))
        XCTAssertEqual(Route.Component(stringLiteral: "test"), .constant("test"))

        XCTAssertEqual(Route.Component(component: ":test"), .parameter("test"))
        XCTAssertEqual(Route.Component(stringLiteral: ":test"), .parameter("test"))

        XCTAssertEqual(Route.Component(component: "*"), .wildcard)
        XCTAssertEqual(Route.Component(stringLiteral: "*"), .wildcard)

        XCTAssertEqual(Route.Component(component: "**"), .catchAll(nil))
        XCTAssertEqual(Route.Component(stringLiteral: "**"), .catchAll(nil))

        XCTAssertEqual(Route.Component(component: "**test"), .catchAll("test"))
        XCTAssertEqual(Route.Component(stringLiteral: "**test"), .catchAll("test"))
    }

    // MARK: description

    func testDescription_ShouldMatchValue() {

        XCTAssertEqual(Route.Component("").description, "")
        XCTAssertEqual(Route.Component("constant").description, "constant")
        XCTAssertEqual(Route.Component(":parameter").description, ":parameter")
        XCTAssertEqual(Route.Component("*").description, "*")
        XCTAssertEqual(Route.Component("**").description, "**")
        XCTAssertEqual(Route.Component("**catchAll").description, "**catchAll")
    }

    // MARK: debugDescription

    func testDebugDescription_ShouldMatchValue() {

        XCTAssertEqual(Route.Component("").debugDescription, ".constant()")
        XCTAssertEqual(Route.Component("constant").debugDescription, ".constant(constant)")
        XCTAssertEqual(Route.Component(":parameter").debugDescription, ".variable(parameter)")
        XCTAssertEqual(Route.Component("*").debugDescription, ".wildcard")
        XCTAssertEqual(Route.Component("**").debugDescription, ".catchAll")
        XCTAssertEqual(Route.Component("**catchAll").debugDescription, ".catchAll(catchAll)")
    }

    // MARK: path

    func testPath_WithEmptyArray_ShouldReturnEmptyString() {

        XCTAssertEqual([Route.Component]().path, "")
    }

    func testPath_WithNotEmptyArray_ShouldReturnCorrectPathString() {

        let componentsA: [Route.Component] = ["some", "path", ":with", "*", "**annotations"]
        XCTAssertEqual(componentsA.path, "some/path/:with/*/**annotations")

        let componentsB: [Route.Component] = ["yet", "another", ":path", "", "**"]
        XCTAssertEqual(componentsB.path, "yet/another/:path//**")
    }
}
