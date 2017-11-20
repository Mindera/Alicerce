//
//  ReusableViewModelView.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 16/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol ReusableViewModelView: ReusableView, View {
    associatedtype ViewModel

    var viewModel: ViewModel? { get set }

    func setUpBindings()
}
