//
//  UIViewControllerTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
import UIKit

@testable import Alicerce

final class UIViewControllerTestCase: XCTestCase {

    func testEmbedIn_UsingAUIViewController_ItShouldReturnAUINavigationControllerWithSelfAsRoot() {
        let rootViewController = UIViewController()

        let navigationController = rootViewController.embedInNavigationController()

        XCTAssertNotNil(navigationController.viewControllers.first)
        XCTAssertEqual(navigationController.viewControllers.first!, rootViewController)
    }
    
    func testEmbedIn_WithAUINavigationControllerSubclass_ItShouldReturnTheSubclassNavigationControllerWithSelfAsRoot() {
        class CustomNavigationController: UINavigationController {}
        
        let viewController = UIViewController()
        
        let navigationController = viewController.embedInNavigationController(withType: CustomNavigationController.self)
        
        XCTAssertNotNil(navigationController.viewControllers.first)
        XCTAssertEqual(navigationController.viewControllers.first!, viewController)
    }
    
    func testTabBarItem_WithTwoImages_ItShouldSetBothImages() {
        let viewController = UIViewController()
        
        let mrMinder = imageFromFile(withBundleClass: DiskMemoryPersistenceTestCase.self,
                                     name: "mr-minder",
                                     type: "png")
        
        viewController.tabBarItem(withSelectedImage: mrMinder, unselectedImage: mrMinder)
        
        let mrMinderData = UIImagePNGRepresentation(mrMinder)
        
        XCTAssertNotNil(viewController.tabBarItem.image)
        XCTAssertNotNil(viewController.tabBarItem.selectedImage)
        XCTAssertEqual(UIImagePNGRepresentation(viewController.tabBarItem.image!), mrMinderData)
        XCTAssertEqual(UIImagePNGRepresentation(viewController.tabBarItem.selectedImage!), mrMinderData)
    }
}
