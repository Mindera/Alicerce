//
//  Configuration.swift
//  Alicerce
//
//  Created by Luís Portela on 26/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Analytics {
    
    /// Anaylitics configuration, used to configure values in the `Analytics`
    ///
    /// 💣 QueueQoS 👉 The qos to be used by the analytics queue
    ///
    /// 💣 extraParameters 👉 The parameters to be merged with the parameters for every request
    public struct Configuration {
        let queueQoS: DispatchQoS
        let extraParameters: Parameters?

        init(queueQoS: DispatchQoS = .default,
             extraParameters: Parameters? = nil) {
            self.queueQoS = queueQoS
            self.extraParameters = extraParameters
        }
    }
}
