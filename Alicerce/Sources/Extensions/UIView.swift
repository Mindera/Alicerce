//
//  UIView.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import UIKit

extension ViewCellReuseIdentifier where Self: UIView {
    static var reuseIdentifier: String { return "\(self)" }
}

extension ViewCellProtocol where Self: UIView {
    
    init() {
        self.init(frame: .zero)
    }
}
