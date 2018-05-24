//
//  AuthenticationChallengeHandler.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 18/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

public protocol AuthenticationChallengeHandler {
    func handle(_ challenge: URLAuthenticationChallenge,
                completionHandler: @escaping Network.AuthenticationCompletionClosure)
}
