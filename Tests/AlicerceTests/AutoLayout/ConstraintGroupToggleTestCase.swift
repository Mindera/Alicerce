import XCTest
@testable import Alicerce


class ConstraintGroupToggleTestCase: BaseConstrainableProxyTestCase {

    private enum TestConstraintGroupKey: Hashable {
        case first
        case second
        case third
    }

    func testNoInitialConstraint_WithEnumKey_ShouldNotActivateConstraints() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        var constraint3: NSLayoutConstraint!

        let _ = ConstraintGroupToggle<TestConstraintGroupKey> { [weak self] in

            guard let self = self else { return nil }

            switch $0 {
            case .first:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint1 = view0.bottom(to: host, offset: -100)
                }

            case .second:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint2 = view0.top(to: host, offset: -100)
                }

            case .third:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint3 = view0.leading(to: host, offset: -100)
                }
            }
        }

        XCTAssertNil(constraint1)
        XCTAssertNil(constraint2)
        XCTAssertNil(constraint3)
    }

    func testInitialConstraint_WithEnumKey_ShouldActivateFirstConstraint() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        var constraint3: NSLayoutConstraint!

        let _ = ConstraintGroupToggle(initial: TestConstraintGroupKey.first) { [weak self] in

            guard let self = self else { return nil }

            switch $0 {
            case .first:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint1 = view0.bottom(to: host, offset: -100)
                }

            case .second:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint2 = view0.top(to: host, offset: -100)
                }

            case .third:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint3 = view0.leading(to: host, offset: -100)
                }
            }
        }

        XCTAssert(constraint1.isActive)
        XCTAssertNil(constraint2)
        XCTAssertNil(constraint3)
    }

    func testActivateOneConstraint_WithEnumKey_ShouldDeactivateFirstConstraintAndActivateSecondConstraint() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        var constraint3: NSLayoutConstraint!

        let group = ConstraintGroupToggle(initial: TestConstraintGroupKey.first) { [weak self] in

            guard let self = self else { return nil }

            switch $0 {
            case .first:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint1 = view0.bottom(to: host, offset: -100)
                }

            case .second:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint2 = view0.top(to: host, offset: -100)
                }

            case .third:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint3 = view0.leading(to: host, offset: -100)
                }
            }
        }

        group.activate(.second)

        XCTAssertFalse(constraint1.isActive)
        XCTAssert(constraint2.isActive)
        XCTAssertNil(constraint3)
    }

    func testActivateTwoConstraints_WithEnumKey_ShouldDeactivateFirstAndSecondConstraintAndActivateThirdConstraint() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        var constraint3: NSLayoutConstraint!

        let group = ConstraintGroupToggle(initial: TestConstraintGroupKey.first) { [weak self] in

            guard let self = self else { return nil }

            switch $0 {
            case .first:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint1 = view0.bottom(to: host, offset: -100)
                }

            case .second:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint2 = view0.top(to: host, offset: -100)
                }

            case .third:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint3 = view0.leading(to: host, offset: -100)
                }
            }
        }

        group.activate(.second)
        group.activate(.third)

        XCTAssertFalse(constraint1.isActive)
        XCTAssertFalse(constraint2.isActive)
        XCTAssert(constraint3.isActive)
    }

    func testReactivateConstraint_WithEnumKey_ShouldDeactivateSecondAndThirdConstraintAndActivateFirstConstraint() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        var constraint3: NSLayoutConstraint!

        let group = ConstraintGroupToggle(initial: TestConstraintGroupKey.first) { [weak self]  in

            guard let self = self else { return nil }

            switch $0 {
            case .first:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint1 = view0.bottom(to: host, offset: -100)
                }

            case .second:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint2 = view0.top(to: host, offset: -100)
                }

            case .third:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint3 = view0.leading(to: host, offset: -100)
                }
            }
        }

        group.activate(.second)
        group.activate(.third)
        group.activate(.first)

        XCTAssertTrue(constraint1.isActive)
        XCTAssertFalse(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)
    }

    func testReActivateConstraintCurrentConstraint_WithEnumKey_ShouldActivateFirstConstraint() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!
        var constraint3: NSLayoutConstraint!

        let group = ConstraintGroupToggle(initial: TestConstraintGroupKey.first) {
            [weak self] in

            guard let self = self else { return nil }

            switch $0 {
            case .first:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint1 = view0.bottom(to: host, offset: -100)
                }

            case .second:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint2 = view0.top(to: host, offset: -100)
                }

            case .third:
                return constrain(self.host, self.view0) { host, view0 in
                   constraint3 = view0.leading(to: host, offset: -100)
                }
            }
        }

        group.activate(.first)

        XCTAssertTrue(constraint1.isActive)
        XCTAssertNil(constraint2)
        XCTAssertNil(constraint3)
    }

    func testActivateUnhandledKeyCase_WithNonFiniteKeySet_ShouldMaintainCurrentConstraint() {

        var constraint1: NSLayoutConstraint!
        var constraint2: NSLayoutConstraint!

        let group = ConstraintGroupToggle(initial: "constraint1") { [weak self]  in

            guard let self = self else { return nil }

            switch $0 {
            case "constraint1":
                return constrain(self.host, self.view0) { host, view0 in
                   constraint1 = view0.bottom(to: host, offset: -100)
                }

            case "constraint2":
                return constrain(self.host, self.view0) { host, view0 in
                   constraint2 = view0.bottom(to: host, offset: -100)
                }

            default:
                return nil
            }

        }

        group.activate("constraint3")

        XCTAssert(constraint1.isActive)
        XCTAssertNil(constraint2)
    }
}
