import XCTest
@testable import Alicerce

class ResourceRetryTestCase: XCTestCase {

    typealias Remote = Float
    typealias Request = Int
    typealias Response = String

    private typealias Policy = ResourceRetry.Policy<Remote, Request, Response>

    private enum MockError: Error {
        case 💩, 👻
    }

    // MARK: - shouldRetry -> noRetry

    // retries

    func testShouldRetry_WhenMaxRetriesExceededOnRetriesPolicy_ShouldReturnNoRetry() {

        let maxRetries = 3
        let policy = Policy.retries(maxRetries)

        let previousErrors = [MockError.👻, .👻, .👻]

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: 0,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case let .noRetry(.retries(max)): XCTAssertEqual(max, maxRetries)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenMaxRetriesExceededOnConstantBackoffPolicyWithRetriesTruncation_ShouldReturnNoRetry() {

        let maxRetries = 3
        let policy = Policy.backoff(.constant(0, .retries(maxRetries)))

        let action = policy.shouldRetry(previousErrors: [MockError.👻, .👻, .👻],
                                        totalDelay: 0,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case let .noRetry(.retries(max)): XCTAssertEqual(max, maxRetries)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenMaxRetriesExceededOnExponentialBackoffPolicyWithRetriesTruncation_ShouldReturnNoRetry() {

        let previousErrors = [MockError.👻, .👻, .👻, .👻]

        let maxRetries = 3
        let baseDelay = 0.1337
        let scale: Policy.Backoff.Scale = { delay, numRetries in
            XCTAssertEqual(delay, baseDelay)
            XCTAssertEqual(numRetries, previousErrors.count)

            return baseDelay
        }
        let policy = Policy.backoff(.exponential(0, scale, .retries(maxRetries)))

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: 0,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case let .noRetry(.retries(max)): XCTAssertEqual(max, maxRetries)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // MARK: - shouldRetry -> noRetry

    // delay

    func testShouldRetry_WhenMaxDelayExceededOnConstantBackoffPolicyWithDelayTruncation_ShouldReturnNoRetry() {

        let maxDelay = 0.1337
        let delay = 0.1337
        let policy = Policy.backoff(.constant(delay, .delay(maxDelay)))

        let totalDelay = maxDelay + 0.001337

        let action = policy.shouldRetry(previousErrors: [],
                                        totalDelay: totalDelay,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case let .noRetry(.delay(max)): XCTAssertEqual(max, maxDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenMaxDelayExceededOnExponentialBackoffPolicyWithDelayTruncation_ShouldReturnNoRetry() {

        let previousErrors = [MockError.👻, .👻, .👻]

        let maxDelay = 0.7331
        let baseDelay = 0.1337
        let scale: Policy.Backoff.Scale = { delay, numRetries in
            XCTAssertEqual(delay, baseDelay)
            XCTAssertEqual(numRetries, previousErrors.count)

            return baseDelay
        }
        let policy = Policy.backoff(.exponential(baseDelay, scale, .delay(maxDelay)))

        let totalDelay = maxDelay + 0.001337

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: totalDelay,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case let .noRetry(.delay(max)): XCTAssertEqual(max, maxDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenCustomRuleReturnsRetry_ShouldReturnRetry() {

        enum CustomError: Error {
            case 🔨
        }

        let previousErrors = [MockError.👻, .👻]
        let totalDelay = 0.1337
        let request = 1337
        let error = MockError.💩
        let payload = Float.pi
        let response = "π"

        let rule: Policy.Rule = { ruleErrors, ruleTotalDelay, ruleRequest, ruleError, rulePayload, ruleResponse in

            XCTAssertDumpsEqual(ruleErrors, previousErrors)
            XCTAssertEqual(ruleTotalDelay, totalDelay)
            XCTAssertEqual(ruleRequest, request)
            XCTAssertDumpsEqual(ruleError, error)
            XCTAssertEqual(rulePayload, payload)
            XCTAssertEqual(ruleResponse, response)

            return .noRetry(.custom(CustomError.🔨))
        }

        let policy = Policy.custom(rule)

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: totalDelay,
                                        request: request,
                                        error: error,
                                        payload: payload,
                                        response: response)

        switch action {
        case .noRetry(.custom(CustomError.🔨)): break // expected action
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // MARK: - shouldRetry -> retry

    func testShouldRetry_WhenMaxRetriesNotExceededOnRetriesPolicy_ShouldReturnRetry() {

        let maxRetries = 3
        let policy = Policy.retries(maxRetries)

        let previousErrors = [MockError.👻, .👻]

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: 0,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case .retry: break // expected action
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenCustomRuleReturnsNoRetry_ShouldReturnNoRetry() {

        let previousErrors = [MockError.👻, .👻]
        let totalDelay = 0.1337
        let request = 1337
        let error = MockError.💩
        let payload = Float.pi
        let response = "π"

        let rule: Policy.Rule = { ruleErrors, ruleTotalDelay, ruleRequest, ruleError, rulePayload, ruleResponse in

            XCTAssertDumpsEqual(ruleErrors, previousErrors)
            XCTAssertEqual(ruleTotalDelay, totalDelay)
            XCTAssertEqual(ruleRequest, request)
            XCTAssertDumpsEqual(ruleError, error)
            XCTAssertEqual(rulePayload, payload)
            XCTAssertEqual(ruleResponse, response)

            return .retry
        }

        let policy = Policy.custom(rule)

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: totalDelay,
                                        request: request,
                                        error: error,
                                        payload: payload,
                                        response: response)

        switch action {
        case .retry: break // expected action
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // MARK: - shouldRetry -> retryAfter

    // retries truncation

    func testShouldRetry_WhenMaxRetriesNotExceededOnConstantBackoffPolicyWithRetriesTruncation_ShouldReturnRetryAfter() {

        let constantDelay = 0.1337
        let maxRetries = 3
        let policy = Policy.backoff(.constant(constantDelay, .retries(maxRetries)))

        let previousErrors = [MockError.👻, .👻]

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: 0,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, constantDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenMaxRetriesNotExceededOnExponentialBackoffPolicyWithRetriesTruncation_ShouldReturnRetryAfter() {

        let previousErrors = [MockError.👻, .👻]

        let maxRetries = 3
        let baseDelay = 0.1337
        let scaledDelay = 0.7331
        let scale: Policy.Backoff.Scale = { delay, numRetries in
            XCTAssertEqual(delay, baseDelay)
            XCTAssertEqual(numRetries, previousErrors.count)

            return scaledDelay
        }
        let policy = Policy.backoff(.exponential(baseDelay, scale, .retries(maxRetries)))

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: 0,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, scaledDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // delay truncation

    func testShouldRetry_WhenMaxDelayNotExceededOnConstantBackoffPolicyWithDelayTruncation_ShouldReturnRetryAfter() {

        let maxDelay = 0.1337
        let constantDelay = 0.01337
        let policy = Policy.backoff(.constant(constantDelay, .delay(maxDelay)))

        let totalDelay = maxDelay - constantDelay

        let action = policy.shouldRetry(previousErrors: [],
                                        totalDelay: totalDelay,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, constantDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenMaxDelayNotExceededOnExponentialBackoffPolicyWithDelayTruncationAndScaledDelayBelowMaxDelay_ShouldReturnRetryAfterWithScaledDelay() {

        let previousErrors = [MockError.👻, .👻, .👻]

        let maxDelay = 0.7331
        let baseDelay = 0.1337
        let scaledDelay = 0.7331
        let scale: Policy.Backoff.Scale = { delay, numRetries in
            XCTAssertEqual(delay, baseDelay)
            XCTAssertEqual(numRetries, previousErrors.count)

            return scaledDelay
        }
        let policy = Policy.backoff(.exponential(baseDelay, scale, .delay(maxDelay)))

        let totalDelay = maxDelay - 0.001337

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: totalDelay,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, scaledDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenMaxDelayNotExceededByScaledDelayOnExponentialBackoffPolicyWithDelayTruncationAndScaledDelayAboveMaxDelay_ShouldReturnRetryAfterWithMaxDelay() {

        let previousErrors = [MockError.👻, .👻, .👻]

        let maxDelay = 0.7331
        let baseDelay = 0.1337
        let scaledDelay = maxDelay + 0.001337 // greater than maxDelay, so that `max` is used on retryAfter
        let scale: Policy.Backoff.Scale = { delay, numRetries in
            XCTAssertEqual(delay, baseDelay)
            XCTAssertEqual(numRetries, previousErrors.count)

            return scaledDelay
        }
        let policy = Policy.backoff(.exponential(baseDelay, scale, .delay(maxDelay)))

        let totalDelay = maxDelay - 0.001337

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: totalDelay,
                                        request: 1337,
                                        error: MockError.💩,
                                        payload: nil,
                                        response: nil)

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, maxDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // custom rule

    func testShouldRetry_WhenCustomRuleReturnsRetryAfter_ShouldReturnRetryAfter() {

        let previousErrors = [MockError.👻, .👻]
        let totalDelay = 0.1337
        let request = 1337
        let error = MockError.💩
        let payload = Float.pi
        let response = "π"

        let retryDelay = 1.337

        let rule: Policy.Rule = { ruleErrors, ruleTotalDelay, ruleRequest, ruleError, rulePayload, ruleResponse in

            XCTAssertDumpsEqual(ruleErrors, previousErrors)
            XCTAssertEqual(ruleTotalDelay, totalDelay)
            XCTAssertEqual(ruleRequest, request)
            XCTAssertDumpsEqual(ruleError, error)
            XCTAssertEqual(rulePayload, payload)
            XCTAssertEqual(ruleResponse, response)

            return .retryAfter(retryDelay)
        }

        let policy = Policy.custom(rule)

        let action = policy.shouldRetry(previousErrors: previousErrors,
                                        totalDelay: totalDelay,
                                        request: request,
                                        error: error,
                                        payload: payload,
                                        response: response)

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, retryDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }
    
}
