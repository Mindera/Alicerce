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

        public var minLevel = Log.Level.error
        public var formatter: LogItemFormatter = Log.StringLogItemFormatter()

        public var instanceId: String {
            return "\(type(of: self))_\(fileURL.absoluteString)"
        }

        internal let fileURL: URL
        internal let fileManager = FileManager.default
        
        //MARK:- Lifecycle

        public init(fileURL: URL) {
            self.fileURL = fileURL
        }

        //MARK:- Public Methods

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
            let formattedLogItem = formatter.format(logItem: item)
            guard !formattedLogItem.characters.isEmpty,
                let formattedLogItemData = formattedLogItem.data(using: .utf8) else { return }

            if fileManager.fileExists(atPath: fileURL.path) {
                guard let fileHandle = try? FileHandle(forWritingTo: fileURL) else {
                    print("Log can't open fileHandle for file \(fileURL.path)")
                    return
                }

                let newlineData = "\n".data(using: .utf8)!
                fileHandle.seekToEndOfFile()
                fileHandle.write(newlineData)
                fileHandle.write(formattedLogItemData)
                fileHandle.closeFile()
            }
            else {
                do {
                    try formattedLogItemData.write(to: fileURL)
                }
                catch {
                    print("Log can't write to file \(fileURL.path)")
                    print("\(error.localizedDescription)")
                }
            }
        }
    }
}
