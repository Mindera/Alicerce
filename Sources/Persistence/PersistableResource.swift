//
//  PersistableResource.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

protocol PersistableResource {
    var persistenceKey: Persistence.Key { get }
}
