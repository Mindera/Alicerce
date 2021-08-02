// Copyright © 2021 Mindera. All rights reserved.

import Danger
let danger = Danger()

let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles
message("These files have changed: \(editedFiles.joined(separator: ", "))")