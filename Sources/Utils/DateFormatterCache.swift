//
//  DateFormatterCache.swift
//  Alicerce
//
//  Created by Filipe Lemos on 02/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

protocol DateFormatterBuilder: Hashable {
    func dateFormatter() -> DateFormatter
}

/// A cache for DateFormatter objects obtained from Hashable builders
class DateFormatterCache {

    fileprivate let cachedDateFormatters: Atomic<[AnyHashable : DateFormatter]> = Atomic([:])

    public func dateFormatter<Builder: DateFormatterBuilder>(_ builder: Builder) -> DateFormatter {

        return cachedDateFormatters.modify {
            if let formatter = $0[builder] { return formatter }

            let formatter = builder.dateFormatter()
            $0[builder] = formatter
            return formatter
        }
    }
}
