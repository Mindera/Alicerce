//
//  ViewModelView.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 05/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol ViewModelView: View {
    associatedtype ViewModel

    var viewModel: ViewModel { get }

    init(viewModel: ViewModel)

    func setUpBindings()
}
