import XCTest
@testable import Alicerce

class ServerTrustEvaluator_ConfigurationTestCase: XCTestCase {

    private typealias Configuration = ServerTrustEvaluator.Configuration
    private typealias PinningPolicy = ServerTrustEvaluator.PinningPolicy
    private typealias PinningPolicyValidationError = ServerTrustEvaluator.PinningPolicyValidationError
    private typealias CertificateCheckingOrder = ServerTrustEvaluator.CertificateCheckingOrder
    private typealias ConfigurationValidationError = ServerTrustEvaluator.ConfigurationValidationError
    private typealias CertificateSPKIBase64EncodedSHA256Hash =
        ServerTrustEvaluator.CertificateSPKIBase64EncodedSHA256Hash

    private let spkiHashA: CertificateSPKIBase64EncodedSHA256Hash = "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY="
    private let spkiHashB: CertificateSPKIBase64EncodedSHA256Hash = "lpkiXF3lLlbN0y3y6W0c/qWqPKC7Us2JM8I7XCdEOCA="

    // MARK: - PinningPolicy

    // success
    
    func testPinningPolicyInit_WithValidDomainAndEnforceBackupPinEnabledAndBackupPins_ShouldSucceed() {
        do {
            let _ = try PinningPolicy(domainName: "mindera.com",
                                      includeSubdomains: true,
                                      expirationDate: .distantFuture,
                                      pinnedHashes: [spkiHashA, spkiHashB],
                                      enforceBackupPin: true)
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    func testPinningPolicyInit_WithValidDomainAndEnforceBackupPinDisabledAndSinglePin_ShouldSucceed() {

        do {
            let _ = try PinningPolicy(domainName: "mindera.com",
                                      includeSubdomains: true,
                                      expirationDate: .distantFuture,
                                      pinnedHashes: [spkiHashA],
                                      enforceBackupPin: false)
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    // failure

    func testPinningPolicyInit_WithEmptyDomain_ShouldFail() {
        do {
            let _ = try PinningPolicy(domainName: "",
                                      includeSubdomains: true,
                                      expirationDate: .distantFuture,
                                      pinnedHashes: [spkiHashA, spkiHashB],
                                      enforceBackupPin: true)

            XCTFail("unexpected success")
        } catch PinningPolicyValidationError.invalidDomainName {
            // expected error
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    func testPinningPolicyInit_WithEmptyPins_ShouldFail() {
        do {
            let _ = try PinningPolicy(domainName: "mindera.com",
                                      includeSubdomains: true,
                                      expirationDate: .distantFuture,
                                      pinnedHashes: [],
                                      enforceBackupPin: true)

            XCTFail("unexpected success")
        } catch PinningPolicyValidationError.emptyPins {
            // expected error
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    func testPinningPolicyInit_WithInvalidPins_ShouldFail() {
        do {
            let invalidPins: Set<CertificateSPKIBase64EncodedSHA256Hash> = [spkiHashA, "💩", "🔥"]

            let _ = try PinningPolicy(domainName: "mindera.com",
                                      includeSubdomains: true,
                                      expirationDate: .distantFuture,
                                      pinnedHashes: invalidPins,
                                      enforceBackupPin: true)

            XCTFail("unexpected success")
        } catch PinningPolicyValidationError.invalidPins(let invalid) {
            XCTAssertEqual(invalid, Set(["💩", "🔥"]))
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    func testPinningPolicyInit_WithEnforceBackupPinEnabledAndSinglePin_ShouldFail() {
        do {
            let _ = try PinningPolicy(domainName: "mindera.com",
                                      includeSubdomains: true,
                                      expirationDate: .distantFuture,
                                      pinnedHashes: [spkiHashA],
                                      enforceBackupPin: true)

            XCTFail("unexpected success")
        } catch PinningPolicyValidationError.missingBackupPin {
            // expected error
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    func testPinningPolicyEquals_WithSameDomainName_ShouldReturnTrue() {
        do {
            let policyA = try PinningPolicy(domainName: "mindera.com",
                                            includeSubdomains: true,
                                            expirationDate: .distantFuture,
                                            pinnedHashes: [spkiHashA],
                                            enforceBackupPin: false)

            let policyB = try PinningPolicy(domainName: "mindera.com",
                                            includeSubdomains: false,
                                            expirationDate: .distantPast,
                                            pinnedHashes: [spkiHashA, spkiHashB],
                                            enforceBackupPin: true)

            XCTAssert(policyA == policyB)
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    func testPinningPolicyEquals_WithDifferentDomainName_ShouldReturnFalsee() {
        do {
            let policyA = try PinningPolicy(domainName: "mindera.com",
                                            includeSubdomains: true,
                                            expirationDate: .distantFuture,
                                            pinnedHashes: [spkiHashA],
                                            enforceBackupPin: false)

            let policyB = try PinningPolicy(domainName: "different.com",
                                            includeSubdomains: false,
                                            expirationDate: .distantPast,
                                            pinnedHashes: [spkiHashA, spkiHashB],
                                            enforceBackupPin: true)

            XCTAssertFalse(policyA == policyB)
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    // MARK: CertificateCheckingOrder

    func testCertificateCheckingOrderIndices_WithRootToLeaf_ShouldReturnDecrementingOrder() {
        let chainLength = 3
        let indices = CertificateCheckingOrder.rootToLeaf.indices(forChainLength: chainLength)

        XCTAssertEqual(indices.map { $0 }, (0..<chainLength).reversed().map { $0 })
    }

    func testCertificateCheckingOrderIndices_WithLeafToRoot_ShouldReturnIncrementingOrder() {
        let chainLength = 3
        let indices = CertificateCheckingOrder.leafToRoot.indices(forChainLength: chainLength)

        XCTAssertEqual(indices.map { $0 }, (0..<chainLength).map { $0 })
    }

    // MARK: Configuration

    func testInitConfiguration_WithNonEmptyPolicies_ShouldSucceed() {
        let policy = try! PinningPolicy(domainName: "mindera.com",
                                        includeSubdomains: true,
                                        expirationDate: .distantFuture,
                                        pinnedHashes: [spkiHashA, spkiHashB],
                                        enforceBackupPin: true)

        do {
            let _ = try Configuration(pinningPolicies: [policy])
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }

    func testInitConfiguration_WithEmptyPolicies_ShouldFail() {
        do {
            let _ = try Configuration(pinningPolicies: [])

            XCTFail("unexpected success")
        } catch ConfigurationValidationError.emptyPolicies {
            // expected error
        } catch {
            return XCTFail("unexpected error \(error)")
        }
    }
    
}
