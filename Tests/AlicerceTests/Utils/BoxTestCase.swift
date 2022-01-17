import XCTest
@testable import Alicerce

class BoxTestCase: XCTestCase {

    func test_init_ShouldWrapValueAndAllowMutation() {

        let value = 1337
        let box = Box<Int>(value)

        XCTAssertEqual(value, box.value)

        let newValue = 7331
        box.value = newValue

        XCTAssertEqual(newValue, box.value)
    }

    func test_propertyWrapper_ShouldWrapValueAndAllowMutation() {

        let value = 1337
        @Box var box = value

        XCTAssertEqual(value, box)

        let newValue = 7331
        box = newValue

        XCTAssertEqual(newValue, box)
    }

    func test_dynamicMember_ShouldExposePropertiesInWrappedValue() {

        struct Foo {

            var foo: Int = 1337
        }

        let box = Box<Foo>(.init())
        XCTAssertEqual(box.foo, 1337)

        @Box var box2 = Foo()
        XCTAssertEqual(_box2.foo, 1337)
    }
}
