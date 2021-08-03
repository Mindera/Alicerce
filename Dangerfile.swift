// Copyright © 2021 Mindera. All rights reserved.

import Danger

let danger = Danger()

// Swiftlint style check, with comment on PR
SwiftLint.lint(.all(directory: nil), inline: true)
