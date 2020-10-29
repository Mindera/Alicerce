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

        XCTAssertTrue(constraint1.isActive)
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

        let one = MockContraintGroup(
            activateClosure: {
                activateClosureOne.fulfill()
            },
            deactivateClosure: {
                deactivateClosureOne.fulfill()
            }
        )

        let two = MockContraintGroup(
            activateClosure: {
                activateClosureTwo.fulfill()
            },
            deactivateClosure: {
                XCTFail()
            }
        )

        let nonFiniteConstraintGroupToggle = ConstraintGroupToggle(
            initial: "constraint1",
            constraintGroups: ["constraint1": one, "constraint2": two]
        )

        nonFiniteConstraintGroupToggle.activate("constraint2")

        wait(
            for: [activateClosureOne, deactivateClosureOne, activateClosureTwo],
            timeout: 1,
            enforceOrder: true
        )
    }
}

private enum TestConstraintGroupKey: Hashable {
    case first
    case second
    case third
}

private final class MockContraintGroup: ConstraintGroup {

    private let activateClosure: () -> Void
    private let deactivateClosure: () -> Void

    public init(activateClosure: @escaping () -> Void, deactivateClosure: @escaping () -> Void) {
        self.activateClosure = activateClosure
        self.deactivateClosure = deactivateClosure
    }

    private var isConstraintActive: Bool = false

    public override var isActive: Bool {
        get { isConstraintActive }
        set { newValue ? activate() : deactivate() }
    }

    private func activate() {
        isConstraintActive = true
        activateClosure()
    }

    private func deactivate() {
        isConstraintActive = false
        deactivateClosure()
    }
}
