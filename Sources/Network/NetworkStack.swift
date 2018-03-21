//
//  NetworkStack.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol NetworkStack {
    associatedtype Remote

    func fetch<R: NetworkResource>(resource: R, completion: @escaping Network.CompletionClosure<R.Remote>)
    -> Cancelable where R.Remote == Remote
}
