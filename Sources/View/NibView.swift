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

    /// Return an `UINib` for the given view, assuming the .xib file will have the same name as the view.
    /// - attention: Generic classes are **not** supported, since they can't be specialized by IB at runtime
    static var nib: UINib {
        assert(!"\(self)".contains("<"), "😢: generic views are not currently supported, since IB can't specialize!")

        return UINib(nibName: "\(self)", bundle: Bundle(for: self))
    }
}
