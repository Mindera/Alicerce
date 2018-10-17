// Copyright © 2018 Mindera. All rights reserved.

import Foundation

extension NSError {

    var isURLErrorCancelled: Bool {
        return domain == NSURLErrorDomain && code == NSURLErrorCancelled
    }
}
