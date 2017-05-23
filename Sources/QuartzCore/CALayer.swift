//
//  CALayer.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 22/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import QuartzCore

extension CALayer {

    static func solidLayer(color: UIColor) -> CALayer {
        return {
            $0.backgroundColor = color.cgColor
            return $0
        }(CALayer())
    }
}
