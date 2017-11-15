//
//  NibView.swift
//  Alicerce
//
//  Created by Luís Afonso on 04/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public protocol NibView {
    static var nib: UINib { get }
}

public extension NibView where Self: UIView {

    static var nib: UINib {

        let bundle = Bundle(for: self)
        let nibName = "\(self)"
        let nib = UINib(nibName: nibName, bundle: bundle)

        return nib
    }
}
