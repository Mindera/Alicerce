import Foundation
import CommonCrypto

// How to retrieve SPKI SHA256 Base64 encoded hashes:
//
// - OpenSSL:
// run  ```
//      openssl x509 -inform der -in <cert_name> -pubkey -noout |
//      openssl pkey -pubin -outform der |
//      openssl dgst -sha256 -binary |
//      openssl enc -base64`
//      ```
//
// - ssllabs.com
// enter the server's URL -> analyse -> go to Certification Paths -> look for "Pin SHA256" entries

extension Data {

    typealias CertificateSPKIBase64EncodedSHA256Hash = ServerTrustEvaluator.CertificateSPKIBase64EncodedSHA256Hash

    func spkiHash(for algorithm: PublicKeyAlgorithm) -> CertificateSPKIBase64EncodedSHA256Hash {

        // add missing ASN1 header for public keys to re-create the subject public key info (SPKI)
        let spkiData = algorithm.asn1HeaderData + self

        var spkiHash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        spkiData.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(spkiData.count), &spkiHash)
        }

        return Data(bytes: spkiHash).base64EncodedString()
    }
}
