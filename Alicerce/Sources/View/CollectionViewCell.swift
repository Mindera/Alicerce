//
//  CollectionViewCell.swift
//  Alicerce
//
//  Created by Luís Afonso on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

open class CollectionViewCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupLayout()
    }
}

extension CollectionViewCell: View {
    public func setupLayout() {
        fatalError("💥 Did you forget to override the method? 😱")
    }
}
