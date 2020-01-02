import UIKit

/// A route for the application to handle
public enum ApplicationRoute {

    /// A URL route and associated options.
    case url(URL, options: [UIApplication.OpenURLOptionsKey: Any])

    /// A shortcut item route and associated completion closure.
    case shortcutItem(UIApplicationShortcutItem, completion: (Bool) -> Void)

    /// A user activity route and associated restoration closure.
    case userActivity(NSUserActivity, restoration: ([UIUserActivityRestoring]?) -> Void)
}

/// A type representing a router of `ApplicationRoute`'s.
public protocol ApplicationRouter {

    /// Routes the application route.
    /// - Parameter route: the application route to handle.
    func route(_ route: ApplicationRoute)
}
