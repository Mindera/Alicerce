//
//  KeyboardObserver.swift
//  Alicerce
//
//  Created by Luís Portela on 17/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation
import UIKit

public final class KeyboardObserver: NSObject {

    fileprivate var keyboardVisible = false

    private weak var window: UIWindow?

    init(window: UIWindow) {
        self.window = window

        super.init()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tapGestureRecognizer.delegate = self
        self.window?.addGestureRecognizer(tapGestureRecognizer)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow),
                                               name: .UIKeyboardDidShow,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide),
                                               name: .UIKeyboardDidHide,
                                               object: nil)
    }

    // MARK: - Private Methods

    @objc private func keyboardDidShow(_ notification: Notification) {
        guard keyboardVisible == false else { return }

        keyboardVisible = true
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        guard keyboardVisible == true else { return }

        keyboardVisible = false
    }

    @objc private func didTapView() {
        guard keyboardVisible == true else { return }

        window?.endEditing(true)
    }
}

extension KeyboardObserver: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return keyboardVisible
    }
}
