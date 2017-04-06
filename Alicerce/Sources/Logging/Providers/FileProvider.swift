//
//  FileProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class FileProvider {
    
    public var minLevel: Log.Level = .error
    public var formatter: LogItemFormatter = LogItemStringFormatter()
    
    internal let fileURL: URL
    internal let fileManager = FileManager.default
    
    //MARK:- Lifecycle
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    //MARK:- Public Methods 
    
    public func clear() {
        guard self.fileManager.fileExists(atPath: self.fileURL.path) else { return }
        do {
            try fileManager.removeItem(at: self.fileURL)
        }
        catch {
            print("Log file provider could not remove logfile \(self.fileURL).")
        }
    }
}

//MARK:- LogProvider

extension FileProvider: LogProvider {

    public func providerInstanceId() -> String {
        return "\(type(of: self))_\(self.fileURL.absoluteString)"
    }
    
    public func write(item: LogItem) {
        let formattedLogItem = self.formatter.format(logItem: item)
        guard formattedLogItem.characters.count > 0,
            let formattedLogItemData = formattedLogItem.data(using: .utf8) else { return }
            
        if self.fileManager.fileExists(atPath: self.fileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: self.fileURL) {
                let newlineData = "\n".data(using: .utf8)!
                fileHandle.seekToEndOfFile()
                fileHandle.write(newlineData)
                fileHandle.write(formattedLogItemData)
                fileHandle.closeFile()
            }
            else {
                print("Log can't open fileHandle for file \(self.fileURL.path)")
            }
        }
        else {
            do {
                try formattedLogItemData.write(to: self.fileURL)
            }
            catch {
                print("Log can't write to file \(self.fileURL.path)")
                print("\(error.localizedDescription)")
            }
        }
    }
}