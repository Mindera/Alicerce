import UIKit

public enum ApplicationRoute {
    case url(URL, options: [UIApplicationOpenURLOptionsKey : Any])
    @available(iOS 9.0, *)
    case shortcutItem(UIApplicationShortcutItem, completion: (Bool) -> Void)
    case userActivity(NSUserActivity, restoration: ([Any]?) -> Void)
}

public protocol ApplicationRouter {
    func route(_ route: ApplicationRoute)
}
