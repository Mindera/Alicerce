//
//  ViewModelTableViewCell.swift
//  Alicerce
//
//  Created by Luís Portela on 26/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

open class ViewModelTableViewCell<CellViewModel>: TableViewCell, ReusableViewModelView {
    typealias ViewModel = CellViewModel

    open var viewModel: CellViewModel? {
        didSet {
            setUpBindings()
        }
    }

    open func setUpBindings() {
        fatalError("💥 forgot to override? 💣")
    }
}
