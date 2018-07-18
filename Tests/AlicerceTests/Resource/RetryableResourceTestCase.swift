import XCTest
@testable import Alicerce

class RetryableResourceTestCase: XCTestCase {

    private struct MockRetryableResource: RetryableResource {

        typealias Remote = Float
        typealias Request = Int
        typealias Response = String

        var retriedAfterErrors: [Error]
        var totalRetriedDelay: ResourceRetry.Delay

        var retryPolicies: [RetryPolicy]
    }

    private typealias RetryPolicy = MockRetryableResource.RetryPolicy

    private enum MockError: Error {
        case 💣, 💥
    }

    private var resource: MockRetryableResource!

    override func setUp() {
        super.setUp()

        resource = MockRetryableResource(retriedAfterErrors: [], totalRetriedDelay: 0, retryPolicies: [])
    }

    override func tearDown() {
        resource = nil
        super.tearDown()
    }

    // numRetries

    func testNumRetries_MatchesNumberOfRetriedAfterErrors() {

        XCTAssertEqual(resource.numRetries, resource.retriedAfterErrors.count)

        resource.retriedAfterErrors.append(MockError.💣)
        XCTAssertEqual(resource.numRetries, resource.retriedAfterErrors.count)
    }

    // shouldRetry

    func testShouldRetry_WhenRetryPoliciesAreEmpty_ShouldReturnNone() {

        XCTAssert(resource.retryPolicies.isEmpty)

        switch resource.shouldRetry(with: 1337, error: MockError.💥, payload: nil, response: nil) {
        case .none: break // expected action
        default: XCTFail("💥: unexpected action returned!")
        }
    }

    func testShouldRetry_WhenAnyPolicyReturnsNoRetry_ShouldReturnNoRetryAndSkipOtherPolicies() {
        let retryExpectation = expectation(description: "retryRule")
        let noRetryExpectation = expectation(description: "noRetryRule")
        defer { waitForExpectations(timeout: 1) }

        let retryRule: RetryPolicy.Rule = { _, _, _, _, _, _ in
            retryExpectation.fulfill()
            return .retry
        }

        let noRetryRule: RetryPolicy.Rule = { _, _, _, _, _, _ in
            noRetryExpectation.fulfill()
            return .noRetry(.custom(MockError.💣))
        }

        let anotherRetryRule: RetryPolicy.Rule = { _, _, _, _, _, _ in
            XCTFail("😱: shouldn't call retry rule after another returning noRetry!")
            return .retry
        }

        resource.retryPolicies = [.custom(retryRule), .custom(noRetryRule), .custom(anotherRetryRule)]

        switch resource.shouldRetry(with: 1337, error: MockError.💥, payload: nil, response: nil) {
        case .noRetry(.custom(MockError.💣)): break // expected action
        default: XCTFail("💥: unexpected action returned!")
        }
    }

    func testShouldRetry_WhenAPolicyReturnsRetryAfterAfterAnotherHasReturnedRetry_ShouldReturnRetryAfter() {
        let retryExpectation = expectation(description: "retryRule")
        let retryAfterExpectation = expectation(description: "retryAfterRule")
        let anotherRetryExpectation = expectation(description: "anotherRetryRule")
        defer { waitForExpectations(timeout: 1) }

        let testDelay: ResourceRetry.Delay = 1337

        let retryRule: RetryPolicy.Rule = { _, _, _, _, _, _ in
            retryExpectation.fulfill()
            return .retry
        }

        let retryAfterRule: RetryPolicy.Rule = { _, _, _, _, _, _ in
            retryAfterExpectation.fulfill()
            return .retryAfter(testDelay)
        }

        let anotherRetryRule: RetryPolicy.Rule = { _, _, _, _, _, _ in
            anotherRetryExpectation.fulfill()
            return .retry
        }

        resource.retryPolicies = [.custom(retryRule), .custom(retryAfterRule), .custom(anotherRetryRule)]

        switch resource.shouldRetry(with: 1337, error: MockError.💥, payload: nil, response: nil) {
        case .retryAfter(let delay) where delay == testDelay: break // expected action
        default: XCTFail("💥: unexpected action returned!")
        }
    }

    func testShouldRetry_WhenMultiplePoliciesReturnRetryAfter_ShouldReturnRetryAfterWithTheMaximumDelay() {
        let retryAfterExpectationA = expectation(description: "retryAfterRuleA")
        let retryAfterExpectationB = expectation(description: "retryAfterRuleB")
        let retryAfterExpectationC = expectation(description: "retryAfterRuleC")
        defer { waitForExpectations(timeout: 1) }

        let testDelayA: ResourceRetry.Delay = 1337
        let testDelayB: ResourceRetry.Delay = 133337
        let testDelayC: ResourceRetry.Delay = 13337

        let retryAfterRuleA: RetryPolicy.Rule = { _, _, _, _, _, _ in
            retryAfterExpectationA.fulfill()
            return .retryAfter(testDelayA)
        }

        let retryAfterRuleB: RetryPolicy.Rule = { _, _, _, _, _, _ in
            retryAfterExpectationB.fulfill()
            return .retryAfter(testDelayB)
        }

        let retryAfterRuleC: RetryPolicy.Rule = { _, _, _, _, _, _ in
            retryAfterExpectationC.fulfill()
            return .retryAfter(testDelayC)
        }

        resource.retryPolicies = [.custom(retryAfterRuleA), .custom(retryAfterRuleB), .custom(retryAfterRuleC)]

        switch resource.shouldRetry(with: 1337, error: MockError.💥, payload: nil, response: nil) {
        case .retryAfter(let delay) where delay == testDelayB: break // expected action
        default: XCTFail("💥: unexpected action returned!")
        }
    }
}
