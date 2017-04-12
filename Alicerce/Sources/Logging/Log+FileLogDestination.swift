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

        private static let dispatchQueueLabel = "com.mindera.Alicerce.FileLogDestination"

        public private(set) var dispatchQueue: DispatchQueue
        public private(set) var minLevel: Level
        public private(set) var formatter: LogItemFormatter
        public var instanceId: String {
            return "\(type(of: self))_\(fileURL.absoluteString)"
        }

        private let fileURL: URL
        private let fileManager = FileManager.default

        //MARK:- lifecycle

        public init(fileURL: URL,
                    minLevel: Level = Log.Level.error,
                    formatter: LogItemFormatter = Log.StringLogItemFormatter(),
                    dispatchQueue: DispatchQueue = DispatchQueue(label: FileLogDestination.dispatchQueueLabel)) {
            
            self.fileURL = fileURL
            self.minLevel = minLevel
            self.formatter = formatter
            self.dispatchQueue = dispatchQueue
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

        public func write(item: Item, completion: @escaping (LogDestination, Log.Item, Error?) -> Void) {
            dispatchQueue.async { [weak self] in

                guard let strongSelf = self else { return }

                var reportedError: Error?
                defer { completion(strongSelf, item, reportedError) }

                let formattedLogItem = strongSelf.formatter.format(logItem: item)
                guard !formattedLogItem.characters.isEmpty,
                    let formattedLogItemData = formattedLogItem.data(using: .utf8) else { return }

                if strongSelf.fileManager.fileExists(atPath: strongSelf.fileURL.path) {
                    do {
                        let fileHandle = try FileHandle(forWritingTo: strongSelf.fileURL)
                        let newlineData = "\n".data(using: .utf8)!
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(newlineData)
                        fileHandle.write(formattedLogItemData)
                        fileHandle.closeFile()
                    }
                    catch {
                        reportedError = error
                        print("Log can't open fileHandle for file \(strongSelf.fileURL.path)")
                        print("\(error.localizedDescription)")
                        return
                    }
                }
                else {
                    do {
                        try formattedLogItemData.write(to: strongSelf.fileURL)
                    }
                    catch {
                        reportedError = error
                        print("Log can't write to file \(strongSelf.fileURL.path)")
                        print("\(error.localizedDescription)")
                        return
                    }
                }
            }
        }
    }
}
