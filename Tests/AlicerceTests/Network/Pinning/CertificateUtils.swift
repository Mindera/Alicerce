//
//  CertificateUtils.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 21/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation
import Security
@testable import Alicerce

func certificateFromPEMFile(withName name: String, bundleClass: AnyClass = TestDummy.self) -> SecCertificate {
    var certString = stringFromFile(withName: name, type: "pem", bundleClass: bundleClass)

    certString = certString.trimmingCharacters(in: .whitespacesAndNewlines)
    certString = certString.replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
    certString = certString.replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")

    let certData = Data(base64Encoded: certString, options: .ignoreUnknownCharacters)
        .require(hint: "😱: invalid Base64 certificate data!")

    return SecCertificateCreateWithData(nil, certData as CFData).require(hint: "😱: failed to create certificate!")
}

func certificateFromDERFile(withName name: String,
                            type: String = "cer",
                            bundleClass: AnyClass = TestDummy.self) -> SecCertificate {
    precondition(["cer", "der", "crt"].contains(type), "💥: invalid DER file type!")

    let certData = dataFromFile(withName: name, type: type, bundleClass: bundleClass)

    return SecCertificateCreateWithData(nil, certData as CFData).require(hint: "😱: failed to create certificate!")
}

func publicKeyFromDERFile(withName name: String,
                          type: String = "pub",
                          algorithm: PublicKeyAlgorithm,
                          bundleClass: AnyClass = TestDummy.self) -> SecKey {
    let asn1PublicKeyData = dataFromFile(withName: name, type: type)

    var error: Unmanaged<CFError>?
    let publicKey = SecKeyCreateWithData(asn1PublicKeyData as CFData, algorithm.attributes as CFDictionary, &error)
        .require(hint: "🔥: failed to get public key from asn1 data! Error: \(String(describing: error))")

    return publicKey
}

func publicKeyDataFromDERFile(withName name: String,
                              type: String = "pub",
                              algorithm: PublicKeyAlgorithm,
                              bundleClass: AnyClass = TestDummy.self) -> Data {
    let publicKey = publicKeyFromDERFile(withName: name, algorithm: algorithm)

    var error: Unmanaged<CFError>?
    let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error)
        .require(hint: "🔥: failed to get public key data from key reference! Error: \(String(describing: error))")

    return publicKeyData as Data
}

func publicKeyDataFromRawKeyFile(withName name: String,
                                 type: String,
                                 algorithm: PublicKeyAlgorithm,
                                 bundleClass: AnyClass = TestDummy.self) -> Data {
    let rawPublicKeyData = dataFromFile(withName: name, type: type)

    var error1: Unmanaged<CFError>?
    let publicKey = SecKeyCreateWithData(rawPublicKeyData as CFData, algorithm.attributes as CFDictionary, &error1)
        .require(hint: "🔥: failed to get public key from asn1 data! Error: \(String(describing: error1))")

    var error2: Unmanaged<CFError>?
    let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error2)
        .require(hint: "🔥: failed to get public key data from key reference! Error: \(String(describing: error2))")

    return publicKeyData as Data
}

private extension PublicKeyAlgorithm {

    var attributes: [CFString : Any] {
        let (keyType, keySize): (CFString, Int) = {
            switch self {
            case .rsa2048: return (kSecAttrKeyTypeRSA, 2048)
            case .rsa4096: return (kSecAttrKeyTypeRSA, 4096)
            case .ecDsaSecp256r1: return (kSecAttrKeyTypeECSECPrimeRandom, 256)
            case .ecDsaSecp384r1: return (kSecAttrKeyTypeECSECPrimeRandom, 384)
            case .ecDsaSecp521r1: return (kSecAttrKeyTypeECSECPrimeRandom, 521)
            }
        }()

        return [
            kSecAttrKeyType : keyType,
            kSecAttrKeyClass : kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: keySize
        ]
    }
}
