import UIKit

public final class KeyboardObserver: NSObject {

    fileprivate var isKeyboardVisible = false

    private weak var window: UIWindow?
    private weak var tapGestureRecognizer: UITapGestureRecognizer?

    public var shouldTapCancelTouches: Bool {
        didSet {
            tapGestureRecognizer?.cancelsTouchesInView = shouldTapCancelTouches
        }
    }

    /// List of view subclasses that should be ignored by the gesture recognizer. Touches on these views won't get
    /// the keyboard resigned. Default is `[UIControl.self]`.
    public var ignoredViews: [UIView.Type]

    public init(window: UIWindow,
                shouldTapCancelTouches: Bool = false,
                ignoredViews: [UIView.Type] = [UIControl.self]) {

        self.window = window
        self.shouldTapCancelTouches = shouldTapCancelTouches
        self.ignoredViews = ignoredViews

        super.init()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tapGestureRecognizer.cancelsTouchesInView = shouldTapCancelTouches
        tapGestureRecognizer.delegate = self
        self.window?.addGestureRecognizer(tapGestureRecognizer)

        self.tapGestureRecognizer = tapGestureRecognizer

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardBecameVisible),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardBecameInvisible),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
    }

    deinit {
        if let tapGestureRecognizer = self.tapGestureRecognizer {
            window?.removeGestureRecognizer(tapGestureRecognizer)
        }
    }

    // MARK: - Private Methods

    @objc private func keyboardBecameVisible() {
        isKeyboardVisible = true
    }

    @objc private func keyboardBecameInvisible() {
        isKeyboardVisible = false
    }

    @objc private func didTapView() {
        guard isKeyboardVisible == true else { return }

        window?.endEditing(true)
    }
}

extension KeyboardObserver: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        guard isKeyboardVisible, let view = touch.view else { return false }

        return ignoredViews.contains(where: view.isKind) == false
    }
}
