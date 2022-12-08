import XCTest
import Security
@testable import Alicerce

class ServerTrustEvaluatorTestCase: XCTestCase {

    private typealias Configuration = ServerTrustEvaluator.Configuration
    private typealias PinningPolicy = ServerTrustEvaluator.PinningPolicy

    private let rootCertificate = certificateFromDERFile(withName: "MinderaAlicerceRootCA")
    private let intermediateCertificate = certificateFromPEMFile(withName: "MinderaAlicerceIntermediateCA")
    private let leafCertificate = certificateFromPEMFile(withName: "alicerce.mindera.com")
    private let wildcardLeafCertificate = certificateFromPEMFile(withName: "*.alicerce.mindera.com")
    private let selfSignedCertificate = certificateFromPEMFile(withName: "alicerce.mindera.com.self-signed")
    private let geoTrustRootCertificate = certificateFromDERFile(withName: "GeoTrust_Universal_CA")

    private let rootCertificateSPKIHash = "ZCZkFpdPUOjOPrCi/XEGrUsYDeXaHO06ODYC2VC/QL8="
    private let intermediateCertificateSPKIHash = "BW0xLrszX71QGrCRZzbk4Xr1R3BNTn+dgN7lOgAHgVA="
    private let leafCertificateSPKIHash = "V6LeduEpK9IwXPW6F38rc36aof3McZmETZaBSGSL10M="
    private let wildcardLeafCertificateSPKIHash = "V6LeduEpK9IwXPW6F38rc36aof3McZmETZaBSGSL10M="
    private let selfSignedCertificateSPKIHash = "V6LeduEpK9IwXPW6F38rc36aof3McZmETZaBSGSL10M="
    private let geoTrustCertificateSPKIHash = "lpkiXF3lLlbN0y3y6W0c/qWqPKC7Us2JM8I7XCdEOCA="

    private let invalidSPKIHash = "ABCDEFGHIJLKLMNOPQRSTUVWXYZ1234567890abcdef="

    private lazy var validChainTrust = SecTrust.make(fromCertificates: [leafCertificate, intermediateCertificate],
                                                     anchorCertificates: [rootCertificate])

    private lazy var validWildcardChainTrust = SecTrust.make(fromCertificates: [wildcardLeafCertificate,
                                                                                intermediateCertificate],
                                                             anchorCertificates: [rootCertificate])

    private lazy var invalidChainTrust = SecTrust.make(fromCertificates: [selfSignedCertificate,
                                                                          intermediateCertificate],
                                                       anchorCertificates: [rootCertificate])

    private var evaluator: ServerTrustEvaluator!

    override func setUp() {
        super.setUp()
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [rootCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! ServerTrustEvaluator.Configuration(pinningPolicies: [policy])
        evaluator = try! ServerTrustEvaluator(configuration: configuration)
    }

    override func tearDown() {
        evaluator = nil

        super.tearDown()
    }

    // MARK: evaluate

    // domain success

    func testEvaluate_WithValidChainAndPinnedChain_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [rootCertificateSPKIHash,
                                                       intermediateCertificateSPKIHash,
                                                       leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithValidChainAndPinnedRoot_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [rootCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithValidChainAndPinnedIntermediate_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [intermediateCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithValidChainAndPinnedLeaf_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithValidChainAndPinnedBadHashAndLeaf_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [invalidSPKIHash, leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    // domain failure

    func testEvaluate_WithValidChainAndInvalidPin_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [invalidSPKIHash],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy])

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "alicerce.mindera.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.pinVerificationFailed(.pinnedHashNotFound) {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithValidChainAndInvalidPinAndExpiredPolicy_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        expirationDate: .distantPast,
                                        pinnedHashes: ["ABCDEFGHIJLKLMNOPQRSTUVWXYZ1234567890abcdef="],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy])

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "alicerce.mindera.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.domainPolicyExpired {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithValidChainAndNonMatchingPin_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        expirationDate: .distantPast,
                                        pinnedHashes: [leafCertificateSPKIHash],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy], certificateCheckingOrder: .leafToRoot)

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "not.pinned.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.domainNotPinned {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithInvalidChainAndPinnedRoot_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [rootCertificateSPKIHash],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy])

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(invalidChainTrust, hostname: "alicerce.mindera.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.pinVerificationFailed(.evaluation) {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithValidChainWithUnrelatedPinnedRoot_ShouldFail() {
        let unrelatedValidChainTrust = SecTrust.make(fromCertificates: [leafCertificate,
                                                                        geoTrustRootCertificate,
                                                                        intermediateCertificate],
                                                     anchorCertificates: [rootCertificate])

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [geoTrustCertificateSPKIHash],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy])

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(unrelatedValidChainTrust, hostname: "alicerce.mindera.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.pinVerificationFailed(.pinnedHashNotFound) {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    // domain + subdomain success

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsAndValidWildcardChainAndPinnedChain_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        pinnedHashes: [rootCertificateSPKIHash,
                                                       intermediateCertificateSPKIHash,
                                                       leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validWildcardChainTrust, hostname: "pinning.alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsAndValidWildcardChainAndPinnedRoot_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        pinnedHashes: [rootCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validWildcardChainTrust, hostname: "pinning.alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsAndValidWildcardChainAndPinnedIntermediate_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        pinnedHashes: [intermediateCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validWildcardChainTrust, hostname: "pinning.alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsAndValidWildcardChainAndPinnedLeaf_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        pinnedHashes: [leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validWildcardChainTrust, hostname: "pinning.alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsAndValidWildcardChainAndPinnedBadHashAndLeaf_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        pinnedHashes: [invalidSPKIHash, leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validWildcardChainTrust, hostname: "pinning.alicerce.mindera.com")
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

     // domain + subdomain failure

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsValidChainAndInvalidPin_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        pinnedHashes: [invalidSPKIHash],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy])

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validWildcardChainTrust, hostname: "pinning.alicerce.mindera.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.pinVerificationFailed(.pinnedHashNotFound) {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsValidChainAndInvalidPinAndExpiredPolicy_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        expirationDate: .distantPast,
                                        pinnedHashes: ["ABCDEFGHIJLKLMNOPQRSTUVWXYZ1234567890abcdef="],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy])

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validWildcardChainTrust, hostname: "pinning.alicerce.mindera.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.domainPolicyExpired {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsValidChainAndNonMatchingPin_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        expirationDate: .distantPast,
                                        pinnedHashes: [leafCertificateSPKIHash],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy], certificateCheckingOrder: .leafToRoot)

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validWildcardChainTrust, hostname: "not.pinned.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.domainNotPinned {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsInvalidChainAndPinnedRoot_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        pinnedHashes: [rootCertificateSPKIHash],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy])

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(invalidChainTrust, hostname: "pinning.alicerce.mindera.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.pinVerificationFailed(.evaluation) {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndTrueIncludeSubdomainsValidChainWithUnrelatedPinnedRoot_ShouldFail() {
        let unrelatedValidChainTrust = SecTrust.make(fromCertificates: [wildcardLeafCertificate,
                                                                        geoTrustRootCertificate,
                                                                        intermediateCertificate],
                                                     anchorCertificates: [rootCertificate])

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: true,
                                        pinnedHashes: [geoTrustCertificateSPKIHash],
                                        enforceBackupPin: false)

        let configuration = try! Configuration(pinningPolicies: [policy])

        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(unrelatedValidChainTrust, hostname: "pinning.alicerce.mindera.com")
            XCTFail("unexpected success")
        } catch ServerTrustEvaluator.Error.pinVerificationFailed(.pinnedHashNotFound) {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    func testEvaluate_WithSubdomainAndFalseIncludeSubdomainsAndValidChainAndPinnedChain_ShouldFail() {
        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        includeSubdomains: false,
                                        pinnedHashes: [rootCertificateSPKIHash,
                                                       intermediateCertificateSPKIHash,
                                                       leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        do {
            try evaluator.evaluate(validChainTrust, hostname: "pinning.alicerce.mindera.com")
        } catch ServerTrustEvaluator.Error.domainNotPinned {
            // expected error
        } catch {
            XCTFail("evaluate failed with unexpected error: \(error)")
        }
    }

    // MARK: handle

    // success

    func testHandle_WithValidPin_ShouldCallCompletionWithUseCredential() {
        let expectation = self.expectation(description: "completionHandler")
        defer { waitForExpectations(timeout: 1.0) }

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        let protectionSpace = MockURLProtectionSpace(host: "alicerce.mindera.com", mockServerTrust: validChainTrust)
        let testCredential = URLCredential(trust: validChainTrust)
        let testChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                       proposedCredential: testCredential,
                                                       previousFailureCount: 0,
                                                       failureResponse: nil, error: nil,
                                                       sender: DummyAuthenticationChallengeSender())

        evaluator.handle(testChallenge) { challengeDisposition, credential in
            XCTAssertEqual(challengeDisposition, .useCredential)
            XCTAssertEqual(credential, testCredential)

            expectation.fulfill()
        }
    }

    func testHandle_WithNotServerTrustProtectionSpace_ShouldCallCompletionWithPerformDefaultHandling() {
        let expectation = self.expectation(description: "completionHandler")
        defer { waitForExpectations(timeout: 1.0) }

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        let protectionSpace = MockURLProtectionSpace(host: "alicerce.mindera.com",
                                                     authenticationMethod: NSURLAuthenticationMethodNTLM,
                                                     mockServerTrust: validChainTrust)
        let testCredential = URLCredential(trust: validChainTrust)
        let testChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                       proposedCredential: testCredential,
                                                       previousFailureCount: 0,
                                                       failureResponse: nil, error: nil,
                                                       sender: DummyAuthenticationChallengeSender())

        evaluator.handle(testChallenge) { challengeDisposition, credential in
            XCTAssertEqual(challengeDisposition, .performDefaultHandling)
            XCTAssertNil(credential)

            expectation.fulfill()
        }
    }

    func testHandle_WithExpiredPinAndAllowedExpiredPolicies_ShouldCallCompletionWithPerformDefaultHandling() {
        let expectation = self.expectation(description: "completionHandler")
        defer { waitForExpectations(timeout: 1.0) }

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        expirationDate: .distantPast,
                                        pinnedHashes: [invalidSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy],
                                               allowExpiredDomainPolicies: true)
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        let protectionSpace = MockURLProtectionSpace(host: "alicerce.mindera.com", mockServerTrust: validChainTrust)
        let testCredential = URLCredential(trust: validChainTrust)
        let testChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                       proposedCredential: testCredential,
                                                       previousFailureCount: 0,
                                                       failureResponse: nil, error: nil,
                                                       sender: DummyAuthenticationChallengeSender())

        evaluator.handle(testChallenge) { challengeDisposition, credential in
            XCTAssertEqual(challengeDisposition, .performDefaultHandling)
            XCTAssertEqual(credential, nil)

            expectation.fulfill()
        }
    }

    func testHandle_WithNotPinnedDomainAndAllowedNotPinnedDomain_ShouldCallCompletionWithPerformDefaultHandling() {
        let expectation = self.expectation(description: "completionHandler")
        defer { waitForExpectations(timeout: 1.0) }

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        expirationDate: .distantPast,
                                        pinnedHashes: [invalidSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy],
                                               allowNotPinnedDomains: true)
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        let protectionSpace = MockURLProtectionSpace(host: "not.pinned.com", mockServerTrust: validChainTrust)
        let testCredential = URLCredential(trust: validChainTrust)
        let testChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                       proposedCredential: testCredential,
                                                       previousFailureCount: 0,
                                                       failureResponse: nil, error: nil,
                                                       sender: DummyAuthenticationChallengeSender())

        evaluator.handle(testChallenge) { challengeDisposition, credential in
            XCTAssertEqual(challengeDisposition, .performDefaultHandling)
            XCTAssertEqual(credential, nil)

            expectation.fulfill()
        }
    }

    // failure

    func testHandle_WithNilServerTrustInProtectionSpace_ShouldCallCompletionWithCancelAuthenticationChallenge() {
        let expectation = self.expectation(description: "completionHandler")
        defer { waitForExpectations(timeout: 1.0) }

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [leafCertificateSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        let protectionSpace = MockURLProtectionSpace(host: "alicerce.mindera.com",
                                                     mockServerTrust: nil)
        let testCredential = URLCredential(trust: validChainTrust)
        let testChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                       proposedCredential: testCredential,
                                                       previousFailureCount: 0,
                                                       failureResponse: nil, error: nil,
                                                       sender: DummyAuthenticationChallengeSender())

        evaluator.handle(testChallenge) { challengeDisposition, credential in
            XCTAssertEqual(challengeDisposition, .cancelAuthenticationChallenge)
            XCTAssertNil(credential)

            expectation.fulfill()
        }
    }

    func testHandle_WithInvalidPin_ShouldCallCompletionWithCancelAuthenticationChallenge() {
        let expectation = self.expectation(description: "completionHandler")
        defer { waitForExpectations(timeout: 1.0) }

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        pinnedHashes: [invalidSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy])
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        let protectionSpace = MockURLProtectionSpace(host: "alicerce.mindera.com", mockServerTrust: validChainTrust)
        let testCredential = URLCredential(trust: validChainTrust)
        let testChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                       proposedCredential: testCredential,
                                                       previousFailureCount: 0,
                                                       failureResponse: nil, error: nil,
                                                       sender: DummyAuthenticationChallengeSender())

        evaluator.handle(testChallenge) { challengeDisposition, credential in
            XCTAssertEqual(challengeDisposition, .cancelAuthenticationChallenge)
            XCTAssertEqual(credential, nil)

            expectation.fulfill()
        }
    }

    func testHandle_WithExpiredPinAndNotAllowedExpiredPolicies_ShouldCallCompletionWithCancelAuthenticationChallenge() {
        let expectation = self.expectation(description: "completionHandler")
        defer { waitForExpectations(timeout: 1.0) }

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        expirationDate: .distantPast,
                                        pinnedHashes: [invalidSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy],
                                               allowExpiredDomainPolicies: false)
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        let protectionSpace = MockURLProtectionSpace(host: "alicerce.mindera.com", mockServerTrust: validChainTrust)
        let testCredential = URLCredential(trust: validChainTrust)
        let testChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                       proposedCredential: testCredential,
                                                       previousFailureCount: 0,
                                                       failureResponse: nil, error: nil,
                                                       sender: DummyAuthenticationChallengeSender())

        evaluator.handle(testChallenge) { challengeDisposition, credential in
            XCTAssertEqual(challengeDisposition, .cancelAuthenticationChallenge)
            XCTAssertEqual(credential, nil)

            expectation.fulfill()
        }
    }

    func testHandle_WithNotPinnedDomainAndNotAllowedNotPinnedDomain_ShouldCallCompletionWithCancelAuthenticationChallenge() {
        let expectation = self.expectation(description: "completionHandler")
        defer { waitForExpectations(timeout: 1.0) }

        let policy = try! PinningPolicy(domainName: "alicerce.mindera.com",
                                        expirationDate: .distantPast,
                                        pinnedHashes: [invalidSPKIHash],
                                        enforceBackupPin: false)
        let configuration = try! Configuration(pinningPolicies: [policy],
                                               allowNotPinnedDomains: false)
        let evaluator = try! ServerTrustEvaluator(configuration: configuration)

        let protectionSpace = MockURLProtectionSpace(host: "not.pinned.com", mockServerTrust: validChainTrust)
        let testCredential = URLCredential(trust: validChainTrust)
        let testChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                       proposedCredential: testCredential,
                                                       previousFailureCount: 0,
                                                       failureResponse: nil, error: nil,
                                                       sender: DummyAuthenticationChallengeSender())

        evaluator.handle(testChallenge) { challengeDisposition, credential in
            XCTAssertEqual(challengeDisposition, .cancelAuthenticationChallenge)
            XCTAssertEqual(credential, nil)

            expectation.fulfill()
        }
    }
}

final class MockURLProtectionSpace: URLProtectionSpace {

    let mockServerTrust: SecTrust?

    override var serverTrust: SecTrust? { return mockServerTrust }

    init(host: String,
         port: Int = 443,
         authenticationMethod: String = NSURLAuthenticationMethodServerTrust,
         realm: String? = nil,
         mockServerTrust: SecTrust?) {

        self.mockServerTrust = mockServerTrust

        super.init(host: host,
                   port: 443,
                   protocol: NSURLProtectionSpaceHTTPS,
                   realm: nil,
                   authenticationMethod: authenticationMethod)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class DummyAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {

    public func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}

    public func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}

    public func cancel(_ challenge: URLAuthenticationChallenge) {}
}

