import XCTest
@testable import Alicerce

// Guide to extract public key data from a certificate:
//
// 1. Get the public key
//
// run `openssl x509 -inform der -in <certfile> -pubkey -noout | openssl pkey -pubin -outform der -out <keyfile>`
//
// 2. Load the key using `SecKeyCreateWithData`, and then `SecKeyCopyExternalRepresentation`
//
//   RSA Keys (work with plain ASN.1 encoded DER data):
//
//     - you're done, simply load the <keyfile>'s bytes from disk and the above `SecKey` calls should work
//
//   EC Keys (require raw key data, because reasons ¯\_(ツ)_/¯):
//
//    - get dumpasn1 (and dumpasn1.cfg) from https://www.cs.auckland.ac.nz/~pgut001
//    - run `dumpasn1 <keyfile>`, check the offset of the BIT STRING components and its bytes (the key)
//    - run `dumpasn1 -<offset> -f<bitstringkeyfile> <keyfile>`
//    - run `hexdump -Cv <bitstringkeyfile>`, check how many extra bytes are on the file before the key begins
//    - run `dd if=<bistringfile> bs=1 skip=<extrabytes> of=<rawkeyfile>`
//    - load the <rawkeyfile>'s bytes from disk and the above `SecKey` calls should work

class Data_SPKIHashTestCase: XCTestCase {

    func testSPKIHash_WithRSA2048PublicKey_ShouldReturnCorrectHash() {
        let publicKeyData = publicKeyDataFromDERFile(withName: "DigiCertGlobalRootG2", algorithm: .rsa2048)

        XCTAssertEqual(publicKeyData.spkiHash(for: .rsa2048), "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=")
    }

    func testSPKIHash_WithRSA4098PublicKey_ShouldReturnCorrectHash() {
        let publicKeyData = publicKeyDataFromDERFile(withName: "GeoTrust_Universal_CA", algorithm: .rsa4096)

        XCTAssertEqual(publicKeyData.spkiHash(for: .rsa4096), "lpkiXF3lLlbN0y3y6W0c/qWqPKC7Us2JM8I7XCdEOCA=")
    }

    func testSPKIHash_WithECDSASecp256r1PublicKey_ShouldReturnCorrectHash() {
        let publicKeyData = publicKeyDataFromRawKeyFile(withName: "AmazonRootCA3",
                                                        type: "rawpub",
                                                        algorithm: .ecDsaSecp256r1)

        XCTAssertEqual(publicKeyData.spkiHash(for: .ecDsaSecp256r1), "NqvDJlas/GRcYbcWE8S/IceH9cq77kg0jVhZeAPXq8k=")
    }

    func testSPKIHash_WithECDSASecp384r1PublicKey_ShouldReturnCorrectHash() {
        let publicKeyData = publicKeyDataFromRawKeyFile(withName: "AmazonRootCA4",
                                                        type: "rawpub",
                                                        algorithm: .ecDsaSecp384r1)

        XCTAssertEqual(publicKeyData.spkiHash(for: .ecDsaSecp384r1), "9+ze1cZgR9KO1kZrVDxA4HQ6voHRCSVNz4RdTCx4U8U=")
    }

    func testSPKIHash_WithECDSASecp521r1PublicKey_ShouldReturnCorrectHash() {
        let publicKeyData = publicKeyDataFromRawKeyFile(withName: "MinderaAlicerceRootCA",
                                                        type: "rawpub",
                                                        algorithm: .ecDsaSecp521r1)

        XCTAssertEqual(publicKeyData.spkiHash(for: .ecDsaSecp521r1), "ZCZkFpdPUOjOPrCi/XEGrUsYDeXaHO06ODYC2VC/QL8=")
    }
}


