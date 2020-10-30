import XCTest
@testable import Alicerce

class ConstraintGroupToggleTestCase: BaseConstrainableProxyTestCase {

    private var constraintGroupToggle: ConstraintGroupToggle<TestConstraintGroupKey>!

    private var constraintGroup1: ConstraintGroup!
    private var constraintGroup2: ConstraintGroup!
    private var constraintGroup3: ConstraintGroup!

    private var constraint1: NSLayoutConstraint!
    private var constraint2: NSLayoutConstraint!
    private var constraint3: NSLayoutConstraint!

    override func setUp() {
        super.setUp()

        constraintGroup1 = constrain(self.view0, self.view1, activate: false) { view0, view1 in
            self.constraint1 = view0.bottom(to: view1)
        }

        constraintGroup2 = constrain(self.view0, self.view2, activate: false) { view0, view2 in
            self.constraint2 = view0.bottom(to: view2)
        }

        constraintGroup3 = constrain(self.view0, self.view3, activate: false) { view0, view3 in
            self.constraint3 = view0.bottom(to: view3)
        }

        constraintGroupToggle = ConstraintGroupToggle(
            initial: .first,
            constraintGroups: [.first: constraintGroup1, .second: constraintGroup2, .third: constraintGroup3]
        )
    }

    override func tearDown() {

        constraint1 = nil
        constraint2 = nil
        constraint3 = nil

        constraintGroup1 = nil
        constraintGroup2 = nil
        constraintGroup3 = nil

        super.tearDown()
    }

    func testInit_WithNoInitialConstraint_ShouldNotActivateConstraints() {

        constraintGroupToggle = ConstraintGroupToggle(
            constraintGroups: [.first: constraintGroup1, .second: constraintGroup2, .third: constraintGroup3]
        )

        XCTAssertFalse(constraint1.isActive)
        XCTAssertFalse(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)
    }

    func testInit_WithInitialConstraint_ShouldActivateFirstConstraint() {

        XCTAssert(constraint1.isActive)
        XCTAssertFalse(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)
    }

    func testInit_WithNoInitialConstraintGroupsActive_ShouldDeactivateConstraintGroups() {

        constraintGroup1 = constrain(self.view0, self.view1, activate: true) { view0, view1 in
            self.constraint1 = view0.bottom(to: view1)
        }

        constraintGroup2 = constrain(self.view0, self.view2, activate: true) { view0, view2 in
            self.constraint2 = view0.bottom(to: view2)
        }

        constraintGroup3 = constrain(self.view0, self.view3, activate: true) { view0, view3 in
            self.constraint3 = view0.bottom(to: view3)
        }

        constraintGroupToggle = ConstraintGroupToggle(
            constraintGroups: [.first: constraintGroup1, .second: constraintGroup2, .third: constraintGroup3]
        )

        XCTAssertFalse(constraint1.isActive)
        XCTAssertFalse(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)
    }

    func testActivate_WithSecondConstraint_ShouldDeactivateFirstConstraintAndActivateSecondConstraint() {

        constraintGroupToggle.activate(.second)

        XCTAssertFalse(constraint1.isActive)
        XCTAssert(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)
    }

    func testActivate_WithSecondAndThirdConstraint_ShouldDeactivateFirstAndSecondConstraintAndActivateThirdConstraint() {

        constraintGroupToggle.activate(.second)

        XCTAssertFalse(constraint1.isActive)
        XCTAssert(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)

        constraintGroupToggle.activate(.third)

        XCTAssertFalse(constraint1.isActive)
        XCTAssertFalse(constraint2.isActive)
        XCTAssert(constraint3.isActive)
    }

    func testActivate_WithSecondAndFirstConstraint_ShouldDeactivateSecondAndActivateFirstConstraint() {

        constraintGroupToggle.activate(.second)

        XCTAssertFalse(constraint1.isActive)
        XCTAssert(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)

        constraintGroupToggle.activate(.first)

        XCTAssert(constraint1.isActive)
        XCTAssertFalse(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)
    }

    func testActivate_WithUnhandledKey_ShouldDeactivateAllConstraints() {

        let nonFiniteConstraintGroupToggle = ConstraintGroupToggle(
            initial: "constraint1",
            constraintGroups: ["constraint1": constraintGroup2, "constraint2": constraintGroup3]
        )

        nonFiniteConstraintGroupToggle.activate("constraint3")

        XCTAssertFalse(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)
    }

    func testActivate_WithSecondConstraint_ShouldDeactivatePreviouConstraintGroupBeforeActivatingSecond() {

        let activateClosureOne = self.expectation(description: "ConstraintGroup one activated")
        let deactivateClosureOne = self.expectation(description: "ConstraintGroup one deactivated")
        let activateClosureTwo = self.expectation(description: "ConstraintGroup two activated")

        let constraint1Group = MockContraintGroup(constraints: [constraint1])
        constraint1Group.didSetIsActive = { isActive in

            if isActive {
                activateClosureOne.fulfill()
            } else {
                deactivateClosureOne.fulfill()
            }
        }

        let constraint2Group = MockContraintGroup(constraints: [constraint2])
        constraint2Group.didSetIsActive = { isActive in

            if isActive {
                activateClosureTwo.fulfill()
            } else {
                XCTFail()
            }
        }

        let nonFiniteConstraintGroupToggle = ConstraintGroupToggle(
            initial: "constraint1",
            constraintGroups: ["constraint1": constraint1Group, "constraint2": constraint2Group]
        )

        nonFiniteConstraintGroupToggle.activate("constraint2")

        wait(
            for: [activateClosureOne, deactivateClosureOne, activateClosureTwo],
            timeout: 1,
            enforceOrder: true
        )
    }

    func testDeactivate_ShouldDeactivateFirstConstraint() {

        constraintGroupToggle.deactivate()

        XCTAssertFalse(constraint1.isActive)
        XCTAssertFalse(constraint2.isActive)
        XCTAssertFalse(constraint3.isActive)
    }
}

private enum TestConstraintGroupKey: Hashable {
    case first
    case second
    case third
}

private final class MockContraintGroup: ConstraintGroup {

    var didSetIsActive: ((Bool) -> Void)?

    public override init(constraints: [NSLayoutConstraint]) {
        super.init(constraints: constraints)
    }

    public override var isActive: Bool {
        didSet { didSetIsActive?(isActive) }
    }
}
