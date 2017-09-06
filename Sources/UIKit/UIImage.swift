//
//  UIImage.swift
//  Alicerce
//
//  Created by Luís Portela on 03/08/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

extension UIImage {
    var original: UIImage { return withRenderingMode(.alwaysOriginal) }
    var template: UIImage { return withRenderingMode(.alwaysTemplate) }
}
