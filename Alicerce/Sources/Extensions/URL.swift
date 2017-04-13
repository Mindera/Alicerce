//
//  URL.swift
//  Alicerce
//
//  Created by Luís Portela on 19/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension URL {
    
    /// Helper to return URLResourceValues from an Array<URLResourceKey>
    ///
    /// - Parameter forKeys: keys for url attributes
    /// - Returns: URLResourceValues for specified keys
    public func resourceValues(forKeys: [URLResourceKey]) -> URLResourceValues {
        guard let attributes = try? self.resourceValues(forKeys: Set(forKeys)) else {
            assertionFailure("💥 failed to fetch keys attributes \(forKeys) for path 👉 \(absoluteString)")
            
            return URLResourceValues()
        }
        
        return attributes
    }
}
