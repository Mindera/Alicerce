//
//  NSParagraphStyle.swift
//  Alicerce
//
//  Created by Tiago Veloso on 17/02/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

// Credits to: Dmitry Nesterenko
// https://github.com/chebur/StringAttributes

import UIKit

extension NSParagraphStyle {

    public func with(transformer: (NSMutableParagraphStyle) -> ()) -> NSParagraphStyle {
        let copy = mutableCopy() as! NSMutableParagraphStyle
        transformer(copy)
        return copy.copy() as! NSParagraphStyle
    }
}
