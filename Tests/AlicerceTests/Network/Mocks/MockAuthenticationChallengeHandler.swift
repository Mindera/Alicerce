// Copyright © 2018 Mindera. All rights reserved.

import Foundation
@testable import Alicerce

final class MockAuthenticationChallengeHandler: AuthenticationChallengeHandler {

    var mockHandleClosure: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?

    func handle(_ challenge: URLAuthenticationChallenge,
                completionHandler: @escaping Network.AuthenticationCompletionClosure) {
        if let (authChallengeDisposition, credential) = mockHandleClosure?(challenge) {
            return completionHandler(authChallengeDisposition, credential)
        }

        completionHandler(.performDefaultHandling, nil)
    }
}
