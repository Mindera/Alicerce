//
//  CAGradientLayer.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 22/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import QuartzCore

extension CAGradientLayer {

    static func layer(colors: [UIColor],
                      locations: [Float] = [0.0, 1.0],
                      opacity: Float = 1.0,
                      startPoint: CGPoint = .zero,
                      endPoint: CGPoint) -> CAGradientLayer {
        return {
            $0.colors = colors.map { $0.cgColor }
            $0.locations = locations.map { NSNumber(value: $0) }
            $0.opacity = opacity
            $0.startPoint = startPoint
            $0.endPoint = endPoint

            return $0
        }(CAGradientLayer())
    }
}
