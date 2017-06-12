//
//  ViewModelCollectionReusableView.swift
//  Alicerce
//
//  Created by Luís Portela on 12/06/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

open class ViewModelCollectionReusableView<ViewModel>: CollectionReusableView, ReusableViewModelView {

    open var viewModel: ViewModel? {
        didSet {
            setUpBindings()
        }
    }

    open func setUpBindings() {
        fatalError("💥 Did you forget to override the method? 😱")
    }
}
