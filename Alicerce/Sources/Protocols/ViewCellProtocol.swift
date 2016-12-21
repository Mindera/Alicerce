//
//  ViewCellProtocol.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

public protocol ViewCellProtocol: ViewCellReuseIdentifier {
    init()
    
    func setupLayout()
}
