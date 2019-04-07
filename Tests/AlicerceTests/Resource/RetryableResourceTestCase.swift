import XCTest
@testable import Alicerce

class RetryableResourceTestCase: XCTestCase {

    private struct MockRetryableResource: RetryableResource {

        typealias RetryMetadata = String?

        var retryErrors: [Error]
        var totalRetriedDelay: Retry.Delay

        var retryPolicies: [RetryPolicy]
    }

    private typealias RetryPolicy = MockRetryableResource.RetryPolicy

    private enum MockError: Error {
        case 💣, 💥
    }

    private var resource: MockRetryableResource!

    override func setUp() {
        super.setUp()

        resource = MockRetryableResource(retryErrors: [], totalRetriedDelay: 0, retryPolicies: [])
    }

    override func tearDown() {
        resource = nil
        super.tearDown()
    }

    // numRetries

    func testNumRetries_MatchesNumberOfRetriedAfterErrors() {

        XCTAssertEqual(resource.numRetries, resource.retryErrors.count)

        resource.retryErrors.append(MockError.💣)
        XCTAssertEqual(resource.numRetries, resource.retryErrors.count)
    }

    // shouldRetry

    func testShouldRetry_WhenRetryPoliciesAreEmpty_ShouldReturnNone() {

        XCTAssert(resource.retryPolicies.isEmpty)

        switch resource.shouldRetry(with: MockError.💥, metadata: nil) {
        case .none: break // expected action
        default: XCTFail("💥: unexpected action returned!")
        }
    }

    func testShouldRetry_WhenAnyPolicyReturnsNoRetry_ShouldReturnNoRetryAndSkipOtherPolicies() {
        let retryExpectation = expectation(description: "retryRule")
        let noRetryExpectation = expectation(description: "noRetryRule")
        defer { waitForExpectations(timeout: 1) }

        let testError = MockError.💥
        let testMetadata = "🔥"

        let retryRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in

            XCTAssertDumpsEqual(error, testError)
            XCTAssertDumpsEqual(previousErrors, [])
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(metadata, testMetadata)

            retryExpectation.fulfill()
            return .retry
        }

        let noRetryRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in

            XCTAssertDumpsEqual(error, testError)
            XCTAssertDumpsEqual(previousErrors, [])
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(metadata, testMetadata)

            noRetryExpectation.fulfill()
            return .noRetry(.custom(MockError.💣))
        }

        let anotherRetryRule: RetryPolicy.Rule = { _, _, _, _ in

            XCTFail("😱: shouldn't call retry rule after another returning noRetry!")
            return .retry
        }

        resource.retryPolicies = [.custom(retryRule), .custom(noRetryRule), .custom(anotherRetryRule)]

        switch resource.shouldRetry(with: testError, metadata: testMetadata) {
        case .noRetry(.custom(MockError.💣)): break // expected action
        default: XCTFail("💥: unexpected action returned!")
        }
    }

    func testShouldRetry_WhenAPolicyReturnsRetryAfterAfterAnotherHasReturnedRetry_ShouldReturnRetryAfter() {
        let retryExpectation = expectation(description: "retryRule")
        let retryAfterExpectation = expectation(description: "retryAfterRule")
        let anotherRetryExpectation = expectation(description: "anotherRetryRule")
        defer { waitForExpectations(timeout: 1) }

        let testError = MockError.💥
        let testMetadata = "🧨"

        let testDelay: Retry.Delay = 1337

        let retryRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in

            XCTAssertDumpsEqual(error, testError)
            XCTAssertDumpsEqual(previousErrors, [])
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(metadata, testMetadata)

            retryExpectation.fulfill()
            return .retry
        }

        let retryAfterRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in

            XCTAssertDumpsEqual(error, testError)
            XCTAssertDumpsEqual(previousErrors, [])
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(metadata, testMetadata)

            retryAfterExpectation.fulfill()
            return .retryAfter(testDelay)
        }

        let anotherRetryRule: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in

            XCTAssertDumpsEqual(error, testError)
            XCTAssertDumpsEqual(previousErrors, [])
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(metadata, testMetadata)

            anotherRetryExpectation.fulfill()
            return .retry
        }

        resource.retryPolicies = [.custom(retryRule), .custom(retryAfterRule), .custom(anotherRetryRule)]

        switch resource.shouldRetry(with: testError, metadata: testMetadata) {
        case .retryAfter(let delay) where delay == testDelay: break // expected action
        default: XCTFail("💥: unexpected action returned!")
        }
    }

    func testShouldRetry_WhenMultiplePoliciesReturnRetryAfter_ShouldReturnRetryAfterWithTheMaximumDelay() {
        let retryAfterExpectationA = expectation(description: "retryAfterRuleA")
        let retryAfterExpectationB = expectation(description: "retryAfterRuleB")
        let retryAfterExpectationC = expectation(description: "retryAfterRuleC")
        defer { waitForExpectations(timeout: 1) }

        let testError = MockError.💥
        let testMetadata = "🧨"

        let testDelayA: Retry.Delay = 1337
        let testDelayB: Retry.Delay = 133337
        let testDelayC: Retry.Delay = 13337

        let retryAfterRuleA: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in

            XCTAssertDumpsEqual(error, testError)
            XCTAssertDumpsEqual(previousErrors, [])
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(metadata, testMetadata)

            retryAfterExpectationA.fulfill()
            return .retryAfter(testDelayA)
        }

        let retryAfterRuleB: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in

            XCTAssertDumpsEqual(error, testError)
            XCTAssertDumpsEqual(previousErrors, [])
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(metadata, testMetadata)

            retryAfterExpectationB.fulfill()
            return .retryAfter(testDelayB)
        }

        let retryAfterRuleC: RetryPolicy.Rule = { error, previousErrors, totalDelay, metadata in

            XCTAssertDumpsEqual(error, testError)
            XCTAssertDumpsEqual(previousErrors, [])
            XCTAssertEqual(totalDelay, 0)
            XCTAssertEqual(metadata, testMetadata)

            retryAfterExpectationC.fulfill()
            return .retryAfter(testDelayC)
        }

        resource.retryPolicies = [.custom(retryAfterRuleA), .custom(retryAfterRuleB), .custom(retryAfterRuleC)]

        switch resource.shouldRetry(with: testError, metadata: testMetadata) {
        case .retryAfter(let delay) where delay == testDelayB: break // expected action
        default: XCTFail("💥: unexpected action returned!")
        }
    }
}
