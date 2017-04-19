//
//  ApplicationRouter.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 13/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public enum ApplicationRoute {
    case url(URL, options: [UIApplicationOpenURLOptionsKey : Any])
    @available(iOS 9.0, *)
    case shortcutItem(UIApplicationShortcutItem, completion: (Bool) -> Void)
    case userActivity(NSUserActivity, restoration: ([Any]?) -> Void)
}

protocol ApplicationRouter {
    func route(_ route: ApplicationRoute)
}
