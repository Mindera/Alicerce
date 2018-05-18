//
//  Log+FileLogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public class FileLogDestination: LogDestination {

        public enum Error: Swift.Error {
            case clearFailed(URL, Swift.Error)
            case openFileFailed(URL, Swift.Error)
            case writeFailed(URL, Swift.Error)
        }

        public let queue: Queue
        public let minLevel: Level
        public let formatter: LogItemFormatter
        public lazy var id: String = "\(type(of: self))_\(self.fileURL.absoluteString)"

        private let fileURL: URL
        private let fileManager = FileManager.default

        // MARK: - Lifecycle

        public init(fileURL: URL,
                    minLevel: Level = .error,
                    formatter: LogItemFormatter = StringLogItemFormatter(),
                    queue: Queue = Queue(label: "com.mindera.alicerce.log.destination.file")) {

            self.fileURL = fileURL
            self.minLevel = minLevel
            self.formatter = formatter
            self.queue = queue
        }

        // MARK: - Public Methods

        public func clear() throws {

            guard fileManager.fileExists(atPath: fileURL.path) else { return }

            do {
                try fileManager.removeItem(at: fileURL)
            }
            catch {
                throw Error.clearFailed(fileURL, error)
            }
        }

        public func write(item: Item, failure: @escaping (Swift.Error) -> ()) {

            queue.dispatchQueue.async { [unowned self] in

                let formattedLogItem = self.formatter.format(logItem: item)
                guard !formattedLogItem.isEmpty, let formattedLogItemData = formattedLogItem.data(using: .utf8)
                else { return }

                guard self.fileManager.fileExists(atPath: self.fileURL.path) else {
                    do {
                        return try formattedLogItemData.write(to: self.fileURL)
                    }
                    catch {
                        return failure(Error.writeFailed(self.fileURL, error))
                    }
                }

                do {
                    let fileHandle = try FileHandle(forWritingTo: self.fileURL)

                    fileHandle.seekToEndOfFile()
                    fileHandle.write("\n".data(using: .utf8)! + formattedLogItemData)
                    fileHandle.closeFile()
                }
                catch {
                    return failure(Error.openFileFailed(self.fileURL, error))
                }
            }
        }
    }
}
