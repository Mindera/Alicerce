//
//  SecCertificate+PublicKeyKeychainTestCase.swift
//  AlicerceKeychainTests
//
//  Created by André Pacheco Neves on 24/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class SecCertificate_PublicKeyKeychainTestCase: XCTestCase {

    // MARK: legacyPublicKeyData

    func testLegacyPublicKeyData_WithRSA2048Certificate_ShouldReturnCorrectData() {
        let certificate = certificateFromDERFile(withName: "DigiCertGlobalRootG2")
        let certificatePubKeyData = publicKeyDataFromDERFile(withName: "DigiCertGlobalRootG2", algorithm: .rsa2048)

        do {
            let publicKeyData = try certificate.legacyPublicKeyData(keychainTag: "Alicerce_1")

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testLegacyPublicKeyData_WithRSA4096Certificate_ShouldReturnCorrectData() {
        let certificate = certificateFromDERFile(withName: "GeoTrust_Universal_CA")
        let certificatePubKeyData = publicKeyDataFromDERFile(withName: "GeoTrust_Universal_CA", algorithm: .rsa4096)

        do {
            let publicKeyData = try certificate.legacyPublicKeyData(keychainTag: "Alicerce_2")

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testLegacyPublicKeyData_WithECDSASecp256r1Certificate_ShouldReturnCorrectData() {
        let certificate = certificateFromDERFile(withName: "AmazonRootCA3")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "AmazonRootCA3",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp256r1)

        do {
            let publicKeyData = try certificate.legacyPublicKeyData(keychainTag: "Alicerce_3")

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testLegacyPublicKeyData_WithECDSASecp384r1Certificate_ShouldReturnCorrectData() {
        let certificate = certificateFromDERFile(withName: "AmazonRootCA4")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "AmazonRootCA4",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp384r1)

        do {
            let publicKeyData = try certificate.legacyPublicKeyData(keychainTag: "Alicerce_4")

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testLegacyPublicKeyData_WithECDSASecp521r1Certificate_ShouldReturnCorrectData() {
        let certificate = certificateFromDERFile(withName: "MinderaAlicerceRootCA")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "MinderaAlicerceRootCA",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp521r1)

        do {
            let publicKeyData = try certificate.legacyPublicKeyData(keychainTag: "Alicerce_5")

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    // failure
    // TODO: test legacyPublicKeyData failure cases
}

