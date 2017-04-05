//
//  LogItemFormatterProtocol
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

protocol LogItemFormatterProtocol {
    func format(logItem: LogItem) -> String
}
