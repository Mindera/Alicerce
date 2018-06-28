import Foundation
@testable import Alicerce

extension Log.Item {

    static let testItem = Log.Item(timestamp: Date(),
                                   module: "module",
                                   level: .verbose,
                                   message: "message",
                                   thread: "thread",
                                   queue: "queue",
                                   file: "filename.ext",
                                   line: 1337,
                                   function: "function")
}
