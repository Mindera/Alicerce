import XCTest
@testable import Alicerce

class Route_ComponentTests: XCTestCase {

    // MARK: init

    // success

    func testInit_WithValidComponent_ShouldSucceed() {

        XCTAssertEqual(try Route.Component(component: "test"), .constant("test"))
        XCTAssertEqual(try Route.Component(component: ":test"), .parameter("test"))
        XCTAssertEqual(try Route.Component(component: "*"), .wildcard)
        XCTAssertEqual(try Route.Component(component: "**"), .catchAll(nil))
        XCTAssertEqual(try Route.Component(component: "**test"), .catchAll("test"))
    }

    // failure

    func testInit_WithValueContainingAForwardSlash_ShouldFail() {

        XCTAssertInitThrowsUnallowedForwardSlash(value: "/")
        XCTAssertInitThrowsUnallowedForwardSlash(value: "/foo")
        XCTAssertInitThrowsUnallowedForwardSlash(value: "foo/")
        XCTAssertInitThrowsUnallowedForwardSlash(value: "fo/o")
    }

    func testInit_WithValueConsistingOfAParameterWithAnEmptyName_ShouldFail() {

        XCTAssertThrowsError(try Route.Component(component: ":"), "🔥 Unexpected success!") {
            guard case Route.InvalidComponentError.emptyParameterName = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }
    }

    func testInit_WithValueConsistingOfAnInvalidWildcard_ShouldFail() {

        XCTAssertThrowsError(try Route.Component(component: "*foo"), "🔥 Unexpected success!") {
            guard case Route.InvalidComponentError.invalidWildcard = $0 else {
                XCTFail("🔥: unexpected error \($0)!")
                return
            }
        }
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

private extension Route_ComponentTests {

    func XCTAssertInitThrowsUnallowedForwardSlash(
        value: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        XCTAssertThrowsError(
            try Route.Component(component: value),
            "🔥 Unexpected success!",
            file: file,
            line: line
        ) {
            guard case Route.InvalidComponentError.unallowedForwardSlash = $0 else {
                XCTFail("🔥: unexpected error \($0)!", file: file, line: line)
                return
            }
        }
    }
}

extension Route.Component: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) { try! self.init(component: value) }
}
