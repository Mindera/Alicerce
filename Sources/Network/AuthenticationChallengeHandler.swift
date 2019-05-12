import Foundation

public protocol AuthenticationChallengeHandler {

    typealias CompletionHandlerClosure = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    func handle(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping CompletionHandlerClosure)
}
