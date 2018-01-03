//
//  KeyboardObserver.swift
//  Alicerce
//
//  Created by Luís Portela on 17/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

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

    public init(window: UIWindow, shouldTapCancelTouches: Bool = false) {
        self.window = window
        self.shouldTapCancelTouches = shouldTapCancelTouches

        super.init()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tapGestureRecognizer.cancelsTouchesInView = shouldTapCancelTouches
        tapGestureRecognizer.delegate = self
        self.window?.addGestureRecognizer(tapGestureRecognizer)

        self.tapGestureRecognizer = tapGestureRecognizer

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow),
                                               name: .UIKeyboardDidShow,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide),
                                               name: .UIKeyboardDidHide,
                                               object: nil)
    }

    deinit {
        if let tapGestureRecognizer = self.tapGestureRecognizer {
            window?.removeGestureRecognizer(tapGestureRecognizer)
        }
    }

    // MARK: - Private Methods

    @objc private func keyboardDidShow() {
        isKeyboardVisible = true
    }

    @objc private func keyboardDidHide() {
        isKeyboardVisible = false
    }

    @objc private func didTapView() {
        guard isKeyboardVisible == true else { return }

        window?.endEditing(true)
    }
}

extension KeyboardObserver: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return isKeyboardVisible
    }
}
