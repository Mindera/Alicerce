//
//  TableViewHeaderFooterView.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import UIKit

open class TableViewHeaderFooterView: UITableViewHeaderFooterView {

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setUpSubviews()
        setUpConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpSubviews()
        setUpConstraints()
    }
}

extension TableViewHeaderFooterView: View {
    open func setUpSubviews() {
        fatalError("💥 Did you forget to override the method? 😱")
    }

    open func setUpConstraints() {
        fatalError("💥 Did you forget to override the method? 😱")
    }
}
