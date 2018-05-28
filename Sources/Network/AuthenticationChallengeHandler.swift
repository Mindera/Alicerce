import Foundation

public protocol AuthenticationChallengeHandler {
    func handle(_ challenge: URLAuthenticationChallenge,
                completionHandler: @escaping Network.AuthenticationCompletionClosure)
}
