import UIKit

// UINavigationController
public extension UIViewController {

    /// Embeds `self` in a subclass of UINavigationController
    ///
    /// - Returns: Subclass of UINavigationController with `self` as root
    func embedInNavigationController() -> UINavigationController {
        return embedInNavigationController(withType: UINavigationController.self)
    }

    /// Embeds `self` in a UINavigationController
    ///
    /// - Returns: UINavigationController with `self` as root
    func embedInNavigationController<T: UINavigationController>(withType _: T.Type) -> T {
        return T(rootViewController: self)
    }
}

// UITabBarItem
public extension UIViewController {

    /// Helper method to set tabBarItem images with correct rendering mode
    /// You can change the render mode if you want to render the image
    /// as a template.
    ///
    /// - Parameters:
    ///   - selectedImage: UIImage to show when tab is active
    ///   - unselectedImage: UIImage to show when tab is inactive
    ///   - selectedRenderMode: UIImage.RenderingMode to the selected image. Default .alwaysOriginal
    ///   - unselectedRenderMode: UIImage.RenderingMode to the unselected image. Default .alwaysOriginal
    func tabBarItem(withSelectedImage selectedImage: UIImage?,
                    unselectedImage: UIImage?,
                    selectedRenderMode: UIImage.RenderingMode = .alwaysOriginal,
                    unselectedRenderMode: UIImage.RenderingMode = .alwaysOriginal) {
        tabBarItem.image = unselectedImage?.withRenderingMode(unselectedRenderMode)
        tabBarItem.selectedImage = selectedImage?.withRenderingMode(selectedRenderMode)
    }
}
