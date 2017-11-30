//
//  ViewModelTableViewHeaderFooterView.swift
//  Alicerce
//
//  Created by Luís Portela on 26/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

open class ViewModelTableViewHeaderFooterView<ViewModel>: TableViewHeaderFooterView, ReusableViewModelView {

    open var viewModel: ViewModel? {
        didSet {
            setUpBindings()
        }
    }

    open func setUpBindings() {}
}
