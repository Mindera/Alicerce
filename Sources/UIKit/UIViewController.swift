//
//  UIViewController.swift
//  Alicerce
//
//  Created by Luís Portela on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

// UINavigationController
public extension UIViewController {
    
    /// Embeds `self` in a subclass of UINavigationController
    ///
    /// - Returns: Subclass of UINavigationController with `self` as root
    public func embedInNavigationController() -> UINavigationController {
        return embedInNavigationController(withType: UINavigationController.self)
    }
    
    /// Embeds `self` in a UINavigationController
    ///
    /// - Returns: UINavigationController with `self` as root
    public func embedInNavigationController<T: UINavigationController>(withType _: T.Type) -> T {
        return T(rootViewController: self)
    }
}

// UITabBarItem
public extension UIViewController {
    
    /// Helper method to set tabBarItem images with correct rendering mode
    ///
    /// - Parameters:
    ///   - selectedImage: UIImage to show when tab is active
    ///   - unselectedImage: UIImage to show when tab is inactive
    public func tabBarItem(withSelectedImage selectedImage: UIImage?, unselectedImage: UIImage?) {
        tabBarItem.image = unselectedImage?.withRenderingMode(.alwaysOriginal)
        tabBarItem.selectedImage = selectedImage?.withRenderingMode(.alwaysOriginal)
    }
}
