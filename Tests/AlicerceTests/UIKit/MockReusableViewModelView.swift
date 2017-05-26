//
//  MockReusableViewModelView.swift
//  Alicerce
//
//  Created by Luís Portela on 26/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

@testable import Alicerce

struct MockReusableViewModelView {
    let testProperty = "😎"
}

extension MockReusableViewModelView: Equatable {
    static func ==(lhs: MockReusableViewModelView, rhs: MockReusableViewModelView) -> Bool {
        return lhs.testProperty == rhs.testProperty
    }
}
