//
//  ServerTrustEvaluator.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 14/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation
import Security

// Heavily inspired by https://github.com/datatheorem/TrustKit 🙏

public final class ServerTrustEvaluator {

    // tag used to add and find the public key in the Keychain
    static let keychainPublicKeyTag = "com.mindera.alicerce.ServerTrustEvaluator.keychainPublicKeyTag"

    let configuration: Configuration

    private let keychainLock: Lock

    // MARK: - Lifecycle

    public init(configuration: Configuration) throws {

        self.configuration = configuration
        self.keychainLock = Lock.make()

        if #available(iOS 10, *) {}
        else {
            // attributes to cleanup the Keychain in case the App previously crashed
            let publicKeyGet: [CFString : Any] = [
                kSecClass : kSecClassKey,
                kSecAttrApplicationTag : ServerTrustEvaluator.keychainPublicKeyTag,
                kSecReturnData : true
            ]

            switch SecItemDelete(publicKeyGet as CFDictionary) {
            case errSecSuccess: break
            case let error: throw Error.deletePublicKeyFromKeychain(error)
            }
        }
    }

    // MARK: - Public methods

    public func evaluate(_ trust: SecTrust, hostname: String) throws {

        let today = Date()

        // ensure we check `.domain` first, and then the `.anyDomain` wildcard
        for (domainPolicy, pinnedHashes) in configuration.pinningPolicies.sorted(by: { $0.key < $1.key }) {
            do {
                switch domainPolicy {
                case let .domain(domain, false, nil) where hostname == domain,
                     let .domain(domain, true, nil) where hostname.isSubDomain(of: domain):
                    return try verifyPublicKeyPin(of: trust, hostname: hostname, pinnedHashes: pinnedHashes)
                case let .domain(domain, false, date?) where hostname == domain && date < today,
                     let .domain(domain, true, date?) where hostname.isSubDomain(of: domain) && date < today:
                    return try verifyPublicKeyPin(of: trust, hostname: hostname, pinnedHashes: pinnedHashes)
                case let .domain(domain, false, date?) where hostname == domain && date >= today,
                     let .domain(domain, true, date?) where hostname.isSubDomain(of: domain) && date >= today:
                    throw Error.domainPolicyExpired
                case .anyDomain(nil):
                    return try verifyPublicKeyPin(of: trust, hostname: hostname, pinnedHashes: pinnedHashes)
                case let .anyDomain(date?) where date < today:
                    return try verifyPublicKeyPin(of: trust, hostname: hostname, pinnedHashes: pinnedHashes)
                case let .anyDomain(date?) where date >= today:
                    throw Error.domainPolicyExpired
                default:
                    break
                }
            } catch Error.domainPolicyExpired {
                throw Error.domainPolicyExpired
            } catch {
                throw Error.validationFailed(error)
            }
        }

        // at this point, we didn't match any policy in the configured policies
        throw Error.domainNotPinned
    }

    public func publicKeyData(from certificate: SecCertificate) throws -> (Data, PublicKeyAlgorithm?) {

        // create an X509 trust for the certificate
        var newTrust: SecTrust?
        let policy = SecPolicyCreateBasicX509()

        switch SecTrustCreateWithCertificates(certificate, policy, &newTrust) {
        case errSecSuccess: break
        case let error: throw PublicKeyDataExtractionError.createTrust(error)
        }

        guard let trust = newTrust else { throw PublicKeyDataExtractionError.createTrust(nil) }

        // validate the newly created certificate trust
        switch SecTrustEvaluate(trust, nil) {
        case errSecSuccess: break
        case let error: throw PublicKeyDataExtractionError.trustEvaluation(error)
        }

        // get a public key reference from the certificate trust
        guard let publicKey = SecTrustCopyPublicKey(trust) else {
            throw PublicKeyDataExtractionError.copyPublicKey(trust)
        }

        if #available(iOS 10.0, *) {
            // copy the public key bytes from the key reference
            var error: Unmanaged<CFError>?
            guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
                throw PublicKeyDataExtractionError.copyPublicKeyExternalRepresentation(publicKey,
                                                                                       error?.takeRetainedValue())
            }

            let algorithm: PublicKeyAlgorithm? = {
                guard let attributes = SecKeyCopyAttributes(publicKey) as? [CFString : Any] else { return nil }
                return PublicKeyAlgorithm(secKeyAttributes: attributes)
            }()

            return (publicKeyData as Data, algorithm)
        } else {
            // extract the public key bytes from the key reference via Keychain

            // TODO: move this method to a `SecCertificate` extension when on iOS 10+ (and the below code is removed)

            // attributes to add the key
            let peerPublicKeyAdd: [CFString : Any] = [
                kSecClass : kSecClassKey,
                kSecAttrApplicationTag : ServerTrustEvaluator.keychainPublicKeyTag,
                kSecValueRef : publicKey,
                // Avoid issues with background fetching while the device is locked
                kSecAttrAccessible : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                // Request the key's data to be returned
                kSecReturnData : true
            ]

            // attributes to retrieve and delete the key
            let publicKeyGet: [CFString : Any] = [
                kSecClass : kSecClassKey,
                kSecAttrApplicationTag : ServerTrustEvaluator.keychainPublicKeyTag,
                kSecReturnData : true
            ]

            // ensure Keychain add and delete are made atomically
            keychainLock.lock()
            defer { keychainLock.unlock() }

            var publicKeyDataRaw: CFTypeRef?
            switch SecItemAdd(peerPublicKeyAdd as CFDictionary, &publicKeyDataRaw) {
            case errSecSuccess: break
            case let error: throw PublicKeyDataExtractionError.addPublicKeyToKeychain(error)
            }

            switch SecItemDelete(publicKeyGet as CFDictionary) {
            case errSecSuccess: break
            case let error: throw PublicKeyDataExtractionError.deletePublicKeyFromKeychain(error)
            }

            guard let publicKeyData = publicKeyDataRaw as? Data else {
                throw PublicKeyDataExtractionError.getPublicKeyDataFromKeychain
            }

            return (publicKeyData, nil)
        }
    }

    // MARK: - Private methods

    private func verifyPublicKeyPin(of trust: SecTrust,
                                    hostname: String,
                                    pinnedHashes: Set<CertificateSPKIBase64EncodedSHA256Hash>) throws {

        // perform an initial check using the default SSL validation in case it was disabled, as this gives us
        // revocation (only for EV?) and also ensures the certificate chain is sane, and also the full path that
        // successfully validated the chain

        // validate using a sane SSL policy to force hostname validation, even if the supplied trust has a bad policy
        // configured (such as one from `SecPolicyCreateBasicX509()`)
        let sslPolicy = SecPolicyCreateSSL(true, hostname as CFString)
        SecTrustSetPolicies(trust, sslPolicy)

        var trustResult: SecTrustResultType = .invalid

        switch SecTrustEvaluate(trust, &trustResult) {
        case errSecSuccess: break
        case let error: throw PublicKeyVerificationError.evaluation(trustResult, error)
        }

        switch trustResult {
        case .unspecified, .proceed: break
        default: throw PublicKeyVerificationError.sslValidation(trustResult, SecTrustCopyResult(trust))
        }

        let certificateChainLength = SecTrustGetCertificateCount(trust)

        for i in configuration.certificateCheckingOrder.indices(forChainLength: certificateChainLength) {
            guard let certificate = SecTrustGetCertificateAtIndex(trust, i) else {
                throw PublicKeyVerificationError.getCertificate(i)
            }

            do {
                switch try publicKeyData(from: certificate) {
                case let (publicKeyData, publicKeyAlgorithm?):
                    guard pinnedHashes.contains(publicKeyData.spkiHash(for: publicKeyAlgorithm)) else { break }

                    // TODO: perhaps add some `spkiHash` caching?

                    return
                case let (publicKeyData, nil):
                    let isPublicKeyHashPinned: (PublicKeyAlgorithm) -> Bool = {
                        guard pinnedHashes.contains(publicKeyData.spkiHash(for: $0)) else { return false }

                        // TODO: perhaps add some `spkiHash` caching?

                        return true
                    }

                    if let _ = PublicKeyAlgorithm.allValues.first(where: isPublicKeyHashPinned) { return }
                }
            } catch let error {
                throw PublicKeyVerificationError.extractPublicKey(error)
            }
        }

        // at this point, we didn't find any matching SPKI hash in the chain
        throw PublicKeyVerificationError.pinnedHashNotFound
    }
}

// MARK: - AuthenticationChallengeValidator

extension ServerTrustEvaluator: AuthenticationChallengeHandler {

    public func handle(_ challenge: URLAuthenticationChallenge,
                       completionHandler: @escaping Network.AuthenticationCompletionClosure) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            return completionHandler(.performDefaultHandling, nil)
        }

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }

        let serverHostname = challenge.protectionSpace.host

        do {
            try evaluate(serverTrust, hostname: serverHostname)

            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } catch Error.domainNotPinned where configuration.allowNotPinnedDomains {
            completionHandler(.performDefaultHandling, nil)
        } catch Error.domainPolicyExpired where configuration.allowExpiredDomainPolicies {
            completionHandler(.performDefaultHandling, nil)
        } catch {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Nested types

extension ServerTrustEvaluator {

    public enum Error: Swift.Error {
        case domainNotPinned
        case domainPolicyExpired
        case validationFailed(Swift.Error)
        @available(iOS, obsoleted: 10.0, message: "keychain operations to get key data no longer needed on iOS 10+")
        case deletePublicKeyFromKeychain(OSStatus)
    }

    public enum PublicKeyVerificationError: Swift.Error {
        case evaluation(SecTrustResultType, OSStatus)
        case sslValidation(SecTrustResultType, CFDictionary?)
        case getCertificate(CFIndex)
        case extractPublicKey(Swift.Error)
        case pinnedHashNotFound
    }

    enum PublicKeyDataExtractionError: Swift.Error {
        case createTrust(OSStatus?)
        case trustEvaluation(OSStatus)
        case copyPublicKey(SecTrust)
        case copyPublicKeyExternalRepresentation(SecKey, CFError?)
        case addPublicKeyToKeychain(OSStatus)
        case deletePublicKeyFromKeychain(OSStatus)
        case getPublicKeyDataFromKeychain
    }

    public typealias DomainName = String
    public typealias CertificateSPKIBase64EncodedSHA256Hash = String
    public typealias PinningPolicies = [DomainPinningPolicy : Set<CertificateSPKIBase64EncodedSHA256Hash>]

    public enum DomainPinningPolicy: Hashable, Comparable {
        case domain(name: DomainName, allowSubDomains: Bool, expirationDate: Date?)
        case anyDomain(expirationDate: Date?)
        // TODO: possibly add another strategies, e.g. additional trust anchors, allow self signed certificates
    }

    public enum CertificateCheckingOrder {
        case rootToLeaf
        case leafToRoot

        func indices(forChainLength chainLength: Int) -> StrideTo<Int> {
            assert(chainLength > 0)

            switch self {
            case .rootToLeaf: return stride(from: chainLength - 1, to: -1, by: -1)
            case .leafToRoot: return stride(from: 0, to: chainLength, by: 1)
            }
        }
    }

    public struct Configuration {
        let pinningPolicies: PinningPolicies
        let certificateCheckingOrder: CertificateCheckingOrder
        let allowNotPinnedDomains: Bool
        let allowExpiredDomainPolicies: Bool

        public init(pinningPolicies: PinningPolicies,
                    certificateCheckingOrder: CertificateCheckingOrder = .leafToRoot,
                    allowNotPinnedDomains: Bool = false,
                    allowExpiredDomainPolicies: Bool = true) {
            self.pinningPolicies = pinningPolicies
            self.certificateCheckingOrder = certificateCheckingOrder
            self.allowNotPinnedDomains = allowNotPinnedDomains
            self.allowExpiredDomainPolicies = allowExpiredDomainPolicies
        }
    }
}

public extension ServerTrustEvaluator.DomainPinningPolicy {

    // ensure only the domain is considered for equality and hashing
    // considering `expirationDate` might make sense in the future if supporting multiple pinning policies per domain

    static func == (lhs: ServerTrustEvaluator.DomainPinningPolicy,
                    rhs: ServerTrustEvaluator.DomainPinningPolicy) -> Bool {
        switch (lhs, rhs) {
        case (.anyDomain, .anyDomain): return true
        case let (.domain(lhsDomain, _, _), .domain(rhsDomain, _, _)): return lhsDomain == rhsDomain
        default: return false
        }
    }

    var hashValue: Int {
        switch self {
        case .anyDomain: return "*".hashValue
        case let .domain(domain, _, _): return domain.hashValue
        }
    }

    // ensure static domains (and subdomains) will be checked before the `anyDomain` wildcard

    public static func < (lhs: ServerTrustEvaluator.DomainPinningPolicy,
                          rhs: ServerTrustEvaluator.DomainPinningPolicy) -> Bool {
        switch (lhs, rhs) {
        case (.domain, .anyDomain): return true
        default: return false
        }
    }
    
}

// MARK: - Domain helpers

private extension String {

    func isSubDomain(of domain: String) -> Bool {

        // TODO: possibly perform some hostname validations, like total length (255), characters (ASCII only), more?

        let reverseSubDomainComponents = components(separatedBy: ".").reversed()
        let reverseDomainComponents = domain.components(separatedBy: ".").reversed()

        return zip(reverseSubDomainComponents, reverseDomainComponents).first { $0 != $1 }.map { _ in false } ?? true
    }
}
