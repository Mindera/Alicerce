//
//  View.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import UIKit

public protocol View {
    init()
    
    func setupLayout()
}

public extension View where Self: UIView {
    init() {
        self.init(frame: .zero)

        setupLayout()
    }
}
