//
//  TableViewHeaderFooterView.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import UIKit

open class TableViewHeaderFooterView: UITableViewHeaderFooterView, ReusableView {

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupLayout()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupLayout()
    }
}

extension TableViewHeaderFooterView: View {
    public func setupLayout() {
        fatalError("💥 Did you forget to override the method? 😱")
    }
}
