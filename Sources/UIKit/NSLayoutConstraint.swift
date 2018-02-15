//
//  NSConstraintLayout.swift
//  Alicerce
//
//  Created by Tiago Veloso on 15/02/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation
import UIKit

extension NSLayoutConstraint {

    public static func add(constraints: [NSLayoutConstraint]) {

        constraints.forEach {
            if let v = $0.firstItem as? UIView {

                v.translatesAutoresizingMaskIntoConstraints = false
            }
        }

        activate(constraints)
    }
}
