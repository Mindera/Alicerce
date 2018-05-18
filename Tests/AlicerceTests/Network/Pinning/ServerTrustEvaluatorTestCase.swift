//
//  ServerTrustEvaluatorTestCase.swift
//  AlicerceTests
//
//  Created by André Pacheco Neves on 22/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class ServerTrustEvaluatorTestCase: XCTestCase {

    private var evaluator: ServerTrustEvaluator!
    
    override func setUp() {
        super.setUp()

        let configuration = ServerTrustEvaluator.Configuration(pinningPolicies: [:])
        evaluator = try! ServerTrustEvaluator(configuration: configuration)
    }
    
    override func tearDown() {
        evaluator = nil

        super.tearDown()
    }

    // MARK: evaluate

    // MARK: handle

    // MARK: publicKeyData

    // TODO: test iOS 9 code path

    func testPublicKeyData_WithRSA2048Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "DigiCertGlobalRootG2")
        let certificatePubKeyData = publicKeyDataFromDERFile(withName: "DigiCertGlobalRootG2", algorithm: .rsa2048)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try evaluator.publicKeyData(from: certificate)

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .rsa2048)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKeyData_WithRSA4096Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "GeoTrust_Universal_CA")
        let certificatePubKeyData = publicKeyDataFromDERFile(withName: "GeoTrust_Universal_CA", algorithm: .rsa4096)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try evaluator.publicKeyData(from: certificate)

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .rsa4096)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKeyData_WithECDSASecp256r1Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "AmazonRootCA3")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "AmazonRootCA3",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp256r1)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try evaluator.publicKeyData(from: certificate)

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .ecDsaSecp256r1)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKeyData_WithECDSASecp384r1Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "AmazonRootCA4")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "AmazonRootCA4",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp384r1)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try evaluator.publicKeyData(from: certificate)

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .ecDsaSecp384r1)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

    func testPublicKeyData_WithECDSASecp521r1Certificate_ShouldReturnCorrectDataAndAlgorithm() {
        let certificate = certificateFromDERFile(withName: "MinderaAlicerceRootCA")
        let certificatePubKeyData = publicKeyDataFromRawKeyFile(withName: "MinderaAlicerceRootCA",
                                                                type: "rawpub",
                                                                algorithm: .ecDsaSecp521r1)

        do {
            let (publicKeyData, publicKeyAlgorithm) = try evaluator.publicKeyData(from: certificate)

            XCTAssertEqual(publicKeyData, certificatePubKeyData)
            XCTAssertEqual(publicKeyAlgorithm, .ecDsaSecp521r1)
        } catch {
            return XCTFail("unexpected error when extracting public key data: \(error)")
        }
    }

}
