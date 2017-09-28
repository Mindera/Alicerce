//
//  PriorityResource.swift
//  Alicerce
//
//  Created by Pedro Baltarejo on 28/09/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public enum PriorityMode {

    /**
     This mode should make sure that the store tries to fetch data
     from the network stack first, and if it fails checks the
     persistence stack for the data.
     */
    case network

    /**
     This mode should make sure that the store tries to retrieve
     the data from the persistence stack first, and if it fails
     tries to fetch the data from the network stack.
     */
    case persistence
}

public protocol PriorityResource {

    var priority: PriorityMode { get }
}
