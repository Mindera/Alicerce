import XCTest
@testable import Alicerce

class PublicKeyAlgorithmTestCase: XCTestCase {

    func testInitWithSecKeyAttributes_WithRSAKeyTypeAnd2048Bits_ShouldReturnCorrectAlgorithm() {

        let keyAttributes: [CFString : Any] = [
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits : 2048
        ]

        XCTAssertEqual(PublicKeyAlgorithm(secKeyAttributes: keyAttributes), .rsa2048)
    }

    func testInitWithSecKeyAttributes_WithRSAKeyTypeAnd4096Bits_ShouldReturnCorrectAlgorithm() {

        let keyAttributes: [CFString : Any] = [
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits : 4096
        ]

        XCTAssertEqual(PublicKeyAlgorithm(secKeyAttributes: keyAttributes), .rsa4096)
    }

    func testInitWithSecKeyAttributes_WithECKeyTypeAnd256Bits_ShouldReturnCorrectAlgorithm() {

        let keyAttributes1: [CFString : Any] = [
            kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits : 256
        ]

        XCTAssertEqual(PublicKeyAlgorithm(secKeyAttributes: keyAttributes1), .ecDsaSecp256r1)

        let keyAttributes2: [CFString : Any] = [
            kSecAttrKeyType : kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits : 256
        ]

        XCTAssertEqual(PublicKeyAlgorithm(secKeyAttributes: keyAttributes2), .ecDsaSecp256r1)
    }

    func testInitWithSecKeyAttributes_WithECKeyTypeAnd384Bits_ShouldReturnCorrectAlgorithm() {

        let keyAttributes1: [CFString : Any] = [
            kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits : 384
        ]

        XCTAssertEqual(PublicKeyAlgorithm(secKeyAttributes: keyAttributes1), .ecDsaSecp384r1)

        let keyAttributes2: [CFString : Any] = [
            kSecAttrKeyType : kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits : 384
        ]

        XCTAssertEqual(PublicKeyAlgorithm(secKeyAttributes: keyAttributes2), .ecDsaSecp384r1)
    }

    func testInitWithSecKeyAttributes_WithECKeyTypeAnd521Bits_ShouldReturnCorrectAlgorithm() {

        let keyAttributes1: [CFString : Any] = [
            kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits : 521
        ]

        XCTAssertEqual(PublicKeyAlgorithm(secKeyAttributes: keyAttributes1), .ecDsaSecp521r1)

        let keyAttributes2: [CFString : Any] = [
            kSecAttrKeyType : kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits : 521
        ]

        XCTAssertEqual(PublicKeyAlgorithm(secKeyAttributes: keyAttributes2), .ecDsaSecp521r1)
    }
}
