import Foundation
@testable import Alicerce

extension Log.Item {

    static func dummy(
        timestamp: Date = Date(),
        module: String? = "module",
        level: Log.Level = .verbose,
        message: String = "message",
        thread: String = "thread",
        queue: String = "queue",
        file: String = "filename.ext",
        line: Int = 1337,
        function: String = "function"
    ) -> Self {

        .init(
            timestamp: timestamp,
            module: module,
            level: level,
            message: message,
            thread: thread,
            queue: queue,
            file: file,
            line: line,
            function: function
        )
    }
}
