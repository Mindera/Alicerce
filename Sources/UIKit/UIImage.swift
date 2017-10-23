//
//  UIImage.swift
//  Alicerce
//
//  Created by Luís Portela on 03/08/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public extension UIImage {
    public var original: UIImage { return withRenderingMode(.alwaysOriginal) }
    public var template: UIImage { return withRenderingMode(.alwaysTemplate) }
}
