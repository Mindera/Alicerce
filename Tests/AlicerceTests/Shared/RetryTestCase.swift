import XCTest
@testable import Alicerce

class RetryTestCase: XCTestCase {

    private typealias Policy = Retry.Policy<Int>

    private enum MockError: Error {
        case 💩, 👻
    }

    // MARK: - Policy

    // MARK: shouldRetry -> noRetry

    // retries

    func testShouldRetry_WhenMaxRetriesExceededOnRetriesPolicy_ShouldReturnNoRetry() {

        let maxRetries = 3
        let policy = Policy.maxRetries(maxRetries)

        let previousErrors = [MockError.👻, .👻, .👻]

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: previousErrors, totalDelay: 0),
            metadata: 1337
        )

        switch action {
        case let .noRetry(.retries(max)): XCTAssertEqual(max, maxRetries)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenMaxRetriesExceededOnConstantBackoffPolicyWithRetriesTruncation_ShouldReturnNoRetry() {

        let maxRetries = 3
        let policy = Policy.backoff(.constant(delay: 0, until: .maxRetries(maxRetries)))

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: [MockError.👻, .👻, .👻], totalDelay: 0),
            metadata: 1337
        )

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
        let policy = Policy.backoff(.exponential(baseDelay: 0, scale: scale, until: .maxRetries(maxRetries)))

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: previousErrors, totalDelay: 0),
            metadata: 1337
        )

        switch action {
        case let .noRetry(.retries(max)): XCTAssertEqual(max, maxRetries)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // MARK: shouldRetry -> noRetry

    // delay

    func testShouldRetry_WhenMaxDelayExceededOnConstantBackoffPolicyWithDelayTruncation_ShouldReturnNoRetry() {

        let maxDelay = 0.1337
        let delay = 0.1337
        let policy = Policy.backoff(.constant(delay: delay, until: .maxDelay(maxDelay)))

        let totalDelay = maxDelay + 0.001337

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: [], totalDelay: totalDelay),
            metadata: 1337
        )

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
        let policy = Policy.backoff(.exponential(baseDelay: baseDelay, scale: scale, until: .maxDelay(maxDelay)))

        let totalDelay = maxDelay + 0.001337

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: previousErrors, totalDelay: totalDelay),
            metadata: 1337
        )

        switch action {
        case let .noRetry(.delay(max)): XCTAssertEqual(max, maxDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenCustomRuleReturnsRetry_ShouldReturnRetry() {

        enum CustomError: Error {
            case 🔨
        }

        let error = MockError.💩
        let previousErrors = [MockError.👻, .👻]
        let totalDelay = 0.1337
        let metadata = 1337

        let rule: Policy.Rule = { ruleError, ruleState, ruleMetadata in

            XCTAssertDumpsEqual(ruleError, error)
            XCTAssertDumpsEqual(ruleState.errors, previousErrors)
            XCTAssertEqual(ruleState.totalDelay, totalDelay)
            XCTAssertEqual(ruleMetadata, metadata)

            return .noRetry(.custom(CustomError.🔨))
        }

        let policy = Policy.custom(rule)

        let action = policy.shouldRetry(
            with: error,
            state: .init(errors: previousErrors, totalDelay: totalDelay),
            metadata: metadata
        )

        switch action {
        case .noRetry(.custom(CustomError.🔨)): break // expected action
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // MARK: shouldRetry -> retry

    func testShouldRetry_WhenMaxRetriesNotExceededOnRetriesPolicy_ShouldReturnRetry() {

        let maxRetries = 3
        let policy = Policy.maxRetries(maxRetries)

        let previousErrors = [MockError.👻, .👻]

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: previousErrors, totalDelay: 0),
            metadata: 1337
        )

        switch action {
        case .retry: break // expected action
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    func testShouldRetry_WhenCustomRuleReturnsNoRetry_ShouldReturnNoRetry() {

        let error = MockError.💩
        let previousErrors = [MockError.👻, .👻]
        let totalDelay = 0.1337
        let metadata = 1337

        let rule: Policy.Rule = { ruleError, ruleState, ruleMetadata in

            XCTAssertDumpsEqual(ruleError, error)
            XCTAssertDumpsEqual(ruleState.errors, previousErrors)
            XCTAssertEqual(ruleState.totalDelay, totalDelay)
            XCTAssertEqual(ruleMetadata, metadata)

            return .retry
        }

        let policy = Policy.custom(rule)

        let action = policy.shouldRetry(
            with: error,
            state: .init(errors: previousErrors, totalDelay: totalDelay),
            metadata: metadata
        )

        switch action {
        case .retry: break // expected action
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // MARK: shouldRetry -> retryAfter

    // retries truncation

    func testShouldRetry_WhenMaxRetriesNotExceededOnConstantBackoffPolicyWithRetriesTruncation_ShouldReturnRetryAfter() {

        let constantDelay = 0.1337
        let maxRetries = 3
        let policy = Policy.backoff(.constant(delay: constantDelay, until: .maxRetries(maxRetries)))

        let previousErrors = [MockError.👻, .👻]

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: previousErrors, totalDelay: 0),
            metadata: 1337
        )

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
        let scale: Policy.Backoff.Scale = { delay, retry in
            XCTAssertEqual(delay, baseDelay)
            XCTAssertEqual(retry, previousErrors.count + 1)

            return scaledDelay
        }
        let policy = Policy.backoff(.exponential(baseDelay: baseDelay, scale: scale, until: .maxRetries(maxRetries)))

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: previousErrors, totalDelay: 0),
            metadata: 1337
        )

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, scaledDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // delay truncation

    func testShouldRetry_WhenMaxDelayNotExceededOnConstantBackoffPolicyWithDelayTruncation_ShouldReturnRetryAfter() {

        let maxDelay = 0.1337
        let constantDelay = 0.01337
        let policy = Policy.backoff(.constant(delay: constantDelay, until: .maxDelay(maxDelay)))

        let totalDelay = maxDelay - constantDelay

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: [], totalDelay: totalDelay),
            metadata: 1337
        )

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
        let scale: Policy.Backoff.Scale = { delay, retry in
            XCTAssertEqual(delay, baseDelay)
            XCTAssertEqual(retry, previousErrors.count + 1)

            return scaledDelay
        }
        let policy = Policy.backoff(.exponential(baseDelay: baseDelay, scale: scale, until: .maxDelay(maxDelay)))

        let totalDelay = maxDelay - 0.001337

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: previousErrors, totalDelay: totalDelay),
            metadata: 1337
        )

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
        let scale: Policy.Backoff.Scale = { delay, retry in
            XCTAssertEqual(delay, baseDelay)
            XCTAssertEqual(retry, previousErrors.count + 1)

            return scaledDelay
        }
        let policy = Policy.backoff(.exponential(baseDelay: baseDelay, scale: scale, until: .maxDelay(maxDelay)))

        let totalDelay = maxDelay - 0.001337

        let action = policy.shouldRetry(
            with: MockError.💩,
            state: .init(errors: previousErrors, totalDelay: totalDelay),
            metadata: 1337
        )

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, maxDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // custom rule

    func testShouldRetry_WhenCustomRuleReturnsRetryAfter_ShouldReturnRetryAfter() {

        let error = MockError.💩
        let previousErrors = [MockError.👻, .👻]
        let totalDelay = 0.1337
        let metadata = 1337

        let retryDelay = 1.337

        let rule: Policy.Rule = { ruleError, ruleState, ruleMetadata in

            XCTAssertDumpsEqual(ruleError, error)
            XCTAssertDumpsEqual(ruleState.errors, previousErrors)
            XCTAssertEqual(ruleState.totalDelay, totalDelay)
            XCTAssertEqual(ruleMetadata, metadata)

            return .retryAfter(retryDelay)
        }

        let policy = Policy.custom(rule)

        let action = policy.shouldRetry(
            with: error,
            state: .init(errors: previousErrors, totalDelay: totalDelay),
            metadata: metadata
        )

        switch action {
        case .retryAfter(let delay): XCTAssertEqual(delay, retryDelay)
        default: XCTFail("💥: unexpected action \(action) returned!")
        }
    }

    // MARK: - Action

    func testMostPrioritary_WithNoRetryOnEitherSide_ShouldReturnNoRetry() {

        let noRetry = Retry.Action.noRetry(.delay(1.337))

        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(noRetry, .none), noRetry)
        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(noRetry, .retry), noRetry)
        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(noRetry, .retryAfter(1.337)), noRetry)

        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(noRetry, .noRetry(.retries(1337))), noRetry) // "first" wins

        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.none, noRetry), noRetry)
        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.retry, noRetry), noRetry)
        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.retryAfter(1.337), noRetry), noRetry)
    }

    func testMostPrioritary_WithRetryAndNone_ShouldReturnRetry() {

        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.retry, .none), .retry)
        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.none, .retry), .retry)
    }

    func testMostPrioritary_WithRetryAfterAndNone_ShouldReturnRetryAfter() {

        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.retryAfter(1.337), .none), .retryAfter(1.337))
        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.none, .retryAfter(1.337)), .retryAfter(1.337))
    }

    func testMostPrioritary_WithRetryAndRetryAfter_ShouldReturnRetryAfterWithLongerDelay() {

        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.retryAfter(1.337), .retryAfter(13.37)), .retryAfter(13.37))
        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.retryAfter(13.37), .retryAfter(1.337)), .retryAfter(13.37))
    }

    func testMostPrioritary_WithRetryAndRetry_ShouldReturnRetry() {

        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.retry, .retry), .retry)
    }

    func testMostPrioritary_WithNoneAndNone_ShouldReturnNone() {

        XCTAssertDumpsEqual(Retry.Action.mostPrioritary(.none, .none), .none)
    }

    // MARK: - State

    func testEmpty_ShouldHaveEmptyErrorsAndZeroTotalDelay() {

        XCTAssert(Retry.State.empty.errors.isEmpty)
        XCTAssertEqual(Retry.State.empty.totalDelay, 0)
    }

    func testAttemptCount_ShouldReturnErrorCountPlusOne() {

        XCTAssertEqual(Retry.State(errors: [], totalDelay: 0).attemptCount, 1)
        XCTAssertEqual(Retry.State(errors: [MockError.👻], totalDelay: 0).attemptCount, 2)
    }

    func testRetryCount_ShouldReturnErrorCount() {

        XCTAssertEqual(Retry.State(errors: [], totalDelay: 0).retryCount, 0)
        XCTAssertEqual(Retry.State(errors: [MockError.👻], totalDelay: 0).retryCount, 1)
    }

}
