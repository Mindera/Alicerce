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

    public func publicKeyDataAndAlgorithm() throws -> (Data, PublicKeyAlgorithm) {

        let publicKey = try self.publicKey()

        // copy the public key bytes from the key reference
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            throw PublicKeyExtractionError.copyPublicKeyExternalRepresentation(publicKey, error?.takeRetainedValue())
        }

        guard let publicKeyAttributes = SecKeyCopyAttributes(publicKey) as? [CFString : Any] else {
            throw PublicKeyExtractionError.copyPublicKeyAttributes(publicKey)
        }

        guard let algorithm: PublicKeyAlgorithm = PublicKeyAlgorithm(secKeyAttributes: publicKeyAttributes) else {
            throw PublicKeyExtractionError.unknownAlgorithm(publicKey, publicKeyAttributes)
        }

        return (publicKeyData as Data, algorithm)
    }

    public func publicKey() throws -> SecKey {

        // create an X509 trust for the certificate
        var newTrust: SecTrust?
        var result = SecTrustResultType.invalid
        let policy = SecPolicyCreateBasicX509()

        switch SecTrustCreateWithCertificates(self, policy, &newTrust) {
        case errSecSuccess: break
        case let error: throw PublicKeyExtractionError.createTrust(error)
        }

        guard let trust = newTrust else { throw PublicKeyExtractionError.createTrust(nil) }

        // validate the newly created certificate trust
        switch SecTrustEvaluate(trust, &result) {
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
