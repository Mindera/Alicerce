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


    /// Similar to NSLayoutConstraint.activate(), but this method ensures that the views
    /// that are adding the constraints disable translatesAutoresizingMaskIntoConstraints
    ///
    /// - Parameter constraints: an array of constrains to activate
    public static func add(constraints: [NSLayoutConstraint]) {

        constraints.forEach {
            if let v = $0.firstItem as? UIView {

                v.translatesAutoresizingMaskIntoConstraints = false
            }
        }

        activate(constraints)
    }
}
