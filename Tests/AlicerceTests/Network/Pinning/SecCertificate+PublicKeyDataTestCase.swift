//
//  SecCertificate+PublicKeyDataTestCase.swift
//  AlicerceTests
//
//  Created by André Pacheco Neves on 24/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest

class SecCertificate_PublicKeyDataTestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: publicKeyDataAndAlgorithm

    // success

    func testPublicKeyDataAndAlgorithm_WithRSA2048Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "DigiCertGlobalRootG2")
        let certificatePubKeyData = publicKeyDataFromDERFile(withName: "DigiCertGlobalRootG2", algorithm: .rsa2048)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try certificate.publicKeyDataAndAlgorithm()

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .rsa2048)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKeyDataAndAlgorithm_WithRSA4096Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "GeoTrust_Universal_CA")
        let certificatePubKeyData = publicKeyDataFromDERFile(withName: "GeoTrust_Universal_CA", algorithm: .rsa4096)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try certificate.publicKeyDataAndAlgorithm()

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .rsa4096)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKeyDataAndAlgorithm_WithECDSASecp256r1Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "AmazonRootCA3")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "AmazonRootCA3",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp256r1)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try certificate.publicKeyDataAndAlgorithm()

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .ecDsaSecp256r1)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKeyDataAndAlgorithm_WithECDSASecp384r1Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "AmazonRootCA4")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "AmazonRootCA4",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp384r1)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try certificate.publicKeyDataAndAlgorithm()

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .ecDsaSecp384r1)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKeyDataAndAlgorithm_WithECDSASecp521r1Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "MinderaAlicerceRootCA")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "MinderaAlicerceRootCA",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp521r1)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try certificate.publicKeyDataAndAlgorithm()

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .ecDsaSecp521r1)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    // failure
    // TODO: test publicKeyDataAndAlgorithm failure cases

    // MARK: legacyPublicKeyData

    // success

    // failure
    // TODO: test legacyPublicKeyData failure cases

    // MARK: publicKey

    func testPublicKey_WithRSA2048Certificate_ShouldReturnCorrectKey() {
        let certificate = certificateFromDERFile(withName: "DigiCertGlobalRootG2")
        let key = publicKeyFromDERFile(withName: "DigiCertGlobalRootG2", algorithm: .rsa2048)

        do {
            let publicKey = try certificate.publicKey()

            XCTAssertEqual(publicKey, key)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKey_WithRSA4096Certificate_ShouldReturnCorrectKey() {

        let certificate = certificateFromDERFile(withName: "GeoTrust_Universal_CA")
        let key = publicKeyFromDERFile(withName: "GeoTrust_Universal_CA", algorithm: .rsa4096)

        do {
            let publicKey = try certificate.publicKey()

            XCTAssertEqual(publicKey, key)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKey_WithECDSASecp256r1Certificate_ShouldReturnCorrectKey() {
        let certificate = certificateFromDERFile(withName: "AmazonRootCA3")
        let key = publicKeyFromRawKeyFile(withName: "AmazonRootCA3", algorithm: .ecDsaSecp256r1)

        do {
            let publicKey = try certificate.publicKey()

            XCTAssertEqual(publicKey, key)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKey_WithECDSASecp384r1Certificate_ShouldReturnCorrectKey() {
        let certificate = certificateFromDERFile(withName: "AmazonRootCA4")
        let key = publicKeyFromRawKeyFile(withName: "AmazonRootCA4", algorithm: .ecDsaSecp384r1)

        do {
            let publicKey = try certificate.publicKey()

            XCTAssertEqual(publicKey, key)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKey_WithECDSASecp521r1Certificate_ShouldReturnCorrectKey() {
        let certificate = certificateFromDERFile(withName: "MinderaAlicerceRootCA")
        let key = publicKeyFromRawKeyFile(withName: "MinderaAlicerceRootCA", algorithm: .ecDsaSecp521r1)

        do {
            let publicKey = try certificate.publicKey()

            XCTAssertEqual(publicKey, key)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    // failure
    // TODO: test publicKey failure cases
}
