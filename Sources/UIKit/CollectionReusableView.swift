//
//  CollectionReusableView.swift
//  Alicerce
//
//  Created by Luís Afonso on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

open class CollectionReusableView: UICollectionReusableView {

    public override init(frame: CGRect) {
        super.init(frame: frame)

        setUpSubviews()
        setUpConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpSubviews()
        setUpConstraints()
    }

    open func setUpSubviews() {}

    open func setUpConstraints() {}
}
