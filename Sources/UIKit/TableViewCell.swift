//
//  TableViewCell.swift
//  Alicerce
//
//  Created by Luís Afonso on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

open class TableViewCell: UITableViewCell {

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
}

extension TableViewCell: View {
    open func setUpSubviews() {
        fatalError("💥 Did you forget to override the method? 😱")
    }

    open func setUpConstraints() {
        fatalError("💥 Did you forget to override the method? 😱")
    }
}
