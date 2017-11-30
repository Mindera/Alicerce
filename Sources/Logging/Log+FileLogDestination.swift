//
//  Log+FileLogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public class FileLogDestination: LogDestination, LogDestinationFallible {

        public var errorClosure: ((LogDestination, Item, Error) -> ())?

        public let queue: Queue
        public let minLevel: Level
        public let formatter: LogItemFormatter
        public private(set) var writtenItems: Int = 0
        public var instanceId: String {
            return "\(type(of: self))_\(fileURL.absoluteString)"
        }

        private let fileURL: URL
        private let fileManager = FileManager.default

        //MARK:- lifecycle

        public init(fileURL: URL,
                    minLevel: Level = .error,
                    formatter: LogItemFormatter = StringLogItemFormatter(),
                    queue: Queue = Queue(label: "com.mindera.alicerce.log.destination.file")) {

            self.fileURL = fileURL
            self.minLevel = minLevel
            self.formatter = formatter
            self.queue = queue
        }

        //MARK:- public Methods

        public func clear() {
            guard fileManager.fileExists(atPath: fileURL.path) else { return }
            do {
                try fileManager.removeItem(at: fileURL)
            }
            catch {
                print("Log file destination could not remove logfile \(fileURL).")
            }
        }

        public func write(item: Item) {
            queue.dispatchQueue.async { [weak self] in

                guard let strongSelf = self else { return }

                let formattedLogItem = strongSelf.formatter.format(logItem: item)
                guard !formattedLogItem.isEmpty,
                    let formattedLogItemData = formattedLogItem.data(using: .utf8) else { return }

                if strongSelf.fileManager.fileExists(atPath: strongSelf.fileURL.path) {
                    do {
                        let fileHandle = try FileHandle(forWritingTo: strongSelf.fileURL)
                        let newlineData = "\n".data(using: .utf8)!
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(newlineData)
                        fileHandle.write(formattedLogItemData)
                        fileHandle.closeFile()

                        strongSelf.writtenItems += 1
                    }
                    catch {
                        print("Log can't open fileHandle for file \(strongSelf.fileURL.path)")
                        print("\(error.localizedDescription)")

                        strongSelf.errorClosure?(strongSelf, item, error)
                        return
                    }
                }
                else {
                    do {
                        try formattedLogItemData.write(to: strongSelf.fileURL)
                        strongSelf.writtenItems += 1
                    }
                    catch {
                        print("Log can't write to file \(strongSelf.fileURL.path)")
                        print("\(error.localizedDescription)")

                        strongSelf.errorClosure?(strongSelf, item, error)
                        return
                    }
                }
            }
        }
    }
}
