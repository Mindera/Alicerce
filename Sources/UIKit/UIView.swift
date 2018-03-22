//
//  UIView.swift
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

            ($0.firstItem as? UIView)?.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate(constraints)
    }

    public func top(ofView view: UIView, offset: CGFloat = 0.0) {

        UIView.activateConstraints([
            bottomAnchor.constraint(equalTo: view.topAnchor, constant: -offset)
            ])
    }

    public func left(ofView view: UIView, offset: CGFloat = 0.0) {

        UIView.activateConstraints([
            rightAnchor.constraint(equalTo: view.leftAnchor, constant: -offset)
            ])
    }

    public func bottom(ofView view: UIView, offset: CGFloat = 0.0) {

        UIView.activateConstraints([
            topAnchor.constraint(equalTo: view.bottomAnchor, constant: offset)
            ])
    }

    public func right(ofView view: UIView, offset: CGFloat = 0.0) {

        UIView.activateConstraints([
            leftAnchor.constraint(equalTo: view.rightAnchor, constant: offset)
            ])
    }

    public func edges(toView view: UIView, insets: UIEdgeInsets = .zero) {

        UIView.activateConstraints([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leftAnchor.constraint(equalTo: view.leftAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
            rightAnchor.constraint(equalTo: view.rightAnchor, constant: -insets.right)
            ])
    }

    public func center(inView view: UIView, offset: UIOffset = .zero) {

        UIView.activateConstraints([
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset.horizontal),
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset.vertical)
            ])
    }
}
