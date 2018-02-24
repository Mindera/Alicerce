//
//  NSConstraintLayout.swift
//  Alicerce
//
//  Created by Tiago Veloso on 15/02/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    /// Similar to NSLayoutConstraint.activate(), but this method ensures that the views
    /// that are adding the constraints disable translatesAutoresizingMaskIntoConstraints
    ///
    /// - Parameter constraints: an array of constrains to activate
    public static func activateConstraints(_ constraints: [NSLayoutConstraint]) {

        constraints.forEach {

            if let view = $0.firstItem as? UIView {

                view.translatesAutoresizingMaskIntoConstraints = false
            }
        }

        NSLayoutConstraint.activate(constraints)
    }

    func edgesToView(_ view: UIView, insets: UIEdgeInsets = .zero) {

        UIView.activateConstraints([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leftAnchor.constraint(equalTo: view.leftAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
            rightAnchor.constraint(equalTo: view.rightAnchor, constant: -insets.right)
            ])
    }

    func centerInView(_ view: UIView, offset: UIOffset = .zero) {

        UIView.activateConstraints([
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset.horizontal),
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset.vertical)
            ])
    }
}
