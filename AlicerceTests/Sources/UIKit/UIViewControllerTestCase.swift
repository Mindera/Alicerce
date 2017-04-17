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
}
