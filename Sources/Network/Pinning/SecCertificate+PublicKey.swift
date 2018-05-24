//
//  SecCertificate+PublicKey.swift
//  AlicerceTests
//
//  Created by André Pacheco Neves on 24/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation
import Security

extension SecCertificate {

    public enum PublicKeyExtractionError: Swift.Error {
        case createTrust(OSStatus?)
        case trustEvaluation(OSStatus)
        case copyPublicKey(SecTrust)
        case copyPublicKeyExternalRepresentation(SecKey, CFError?)
        case copyPublicKeyAttributes(SecKey)
        case unknownAlgorithm(SecKey, [CFString : Any])
        case addPublicKeyToKeychain(OSStatus)
        case deletePublicKeyFromKeychain(OSStatus)
        case getPublicKeyDataFromKeychain
    }

    @available(iOS 10.0, *)
    public func publicKeyDataAndAlgorithm() throws -> (Data, PublicKeyAlgorithm) {

        let publicKey = try self.publicKey()

        // copy the public key bytes from the key reference
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            throw PublicKeyExtractionError.copyPublicKeyExternalRepresentation(publicKey,
                                                                                   error?.takeRetainedValue())
        }

        guard let publicKeyAttributes = SecKeyCopyAttributes(publicKey) as? [CFString : Any] else {
            throw PublicKeyExtractionError.copyPublicKeyAttributes(publicKey)
        }

        guard let algorithm: PublicKeyAlgorithm = PublicKeyAlgorithm(secKeyAttributes: publicKeyAttributes) else {
            throw PublicKeyExtractionError.unknownAlgorithm(publicKey, publicKeyAttributes)
        }

        return (publicKeyData as Data, algorithm)
    }

    // TODO: remove this method when on iOS 10+
    public func legacyPublicKeyData(keychainTag: String) throws -> Data {

        let publicKey = try self.publicKey()

        // extract the public key bytes from the key reference via Keychain

        // attributes to add the key
        let peerPublicKeyAdd: [CFString : Any] = [
            kSecClass : kSecClassKey,
            kSecAttrApplicationTag : keychainTag,
            kSecValueRef : publicKey,
            // Avoid issues with background fetching while the device is locked
            kSecAttrAccessible : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            // Request the key's data to be returned
            kSecReturnData : true
        ]

        // attributes to retrieve and delete the key
        let publicKeyGet: [CFString : Any] = [
            kSecClass : kSecClassKey,
            kSecAttrApplicationTag : keychainTag,
            kSecReturnData : true
        ]

        var publicKeyDataRaw: CFTypeRef?
        switch SecItemAdd(peerPublicKeyAdd as CFDictionary, &publicKeyDataRaw) {
        case errSecSuccess: break
        case let error: throw PublicKeyExtractionError.addPublicKeyToKeychain(error)
        }

        switch SecItemDelete(publicKeyGet as CFDictionary) {
        case errSecSuccess: break
        case let error: throw PublicKeyExtractionError.deletePublicKeyFromKeychain(error)
        }

        guard let publicKeyData = publicKeyDataRaw as? Data else {
            throw PublicKeyExtractionError.getPublicKeyDataFromKeychain
        }

        return publicKeyData
    }

    public func publicKey() throws -> SecKey {

        // create an X509 trust for the certificate
        var newTrust: SecTrust?
        let policy = SecPolicyCreateBasicX509()

        switch SecTrustCreateWithCertificates(self, policy, &newTrust) {
        case errSecSuccess: break
        case let error: throw PublicKeyExtractionError.createTrust(error)
        }

        guard let trust = newTrust else { throw PublicKeyExtractionError.createTrust(nil) }

        // validate the newly created certificate trust
        switch SecTrustEvaluate(trust, nil) {
        case errSecSuccess: break
        case let error: throw PublicKeyExtractionError.trustEvaluation(error)
        }

        // get a public key reference from the certificate trust
        guard let publicKey = SecTrustCopyPublicKey(trust) else {
            throw PublicKeyExtractionError.copyPublicKey(trust)
        }

        return publicKey
    }
}
