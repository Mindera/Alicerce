import Danger

let danger = Danger()

// Swiftlint style check, with comment on PR
SwiftLint.lint(.all(directory: nil), inline: true)
