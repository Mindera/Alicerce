// Copyright © 2021 Mindera. All rights reserved.

import Danger

let danger = Danger()

// Swiftlint style check, with comment on PR
SwiftLint.lint(.all(directory: nil), inline: true)

// List of all edited files
let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles
message("These files have changed: \(editedFiles.joined(separator: ", "))")
