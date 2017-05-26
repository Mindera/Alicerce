//
//  ViewModelCollectionViewCell.swift
//  Alicerce
//
//  Created by Luís Portela on 26/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

class ViewModelCollectionViewCell<CellViewModel>: CollectionViewCell, ReusableViewModelView {
    typealias ViewModel = CellViewModel

    var viewModel: CellViewModel? {
        didSet {
            setUpBindings()
        }
    }

    func setUpBindings() {
        fatalError("💥 forgot to override? 💣")
    }
}
