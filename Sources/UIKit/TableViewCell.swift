//
//  TableViewCell.swift
//  Alicerce
//
//  Created by Luís Afonso on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

open class TableViewCell: UITableViewCell, View {

    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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
