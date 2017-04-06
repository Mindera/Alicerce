//
//  LogItemFormatter
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

protocol LogItemFormatter {
    func format(logItem: LogItem) -> String
}
