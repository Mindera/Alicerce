import Foundation

public extension Log {

    /// A log destination that outputs log messages to a log file.
    public class FileLogDestination<ItemFormatter: LogItemFormatter, MetadataKey: Hashable>: MetadataLogDestination
    where ItemFormatter.Output == Data {

        /// An error produced by a `FileLogDestination`.
        public enum FileLogDestinationError: Error {

            /// The log file couldn't be cleared (removed).
            case clearFailed(URL, Error)

            /// Formatting a log item failed.
            case itemFormatFailed(Log.Item, Error)

            /// Writing a log item to file failed.
            case itemWriteFailed(URL, Log.Item, Error)

            /// Writing a metadata message to file failed.
            case metadataWriteFailed(URL, [MetadataKey : Any], Data, Error)
        }

        /// A console destinations' log metadata closure, which converts received metadata into a log message that is
        /// forwared to the output closure.
        public typealias LogMetadataClosure = ([MetadataKey : Any]) -> Data

        /// The destination's log item formatter.
        public let formatter: ItemFormatter

        /// The destination's minimum severity log level.
        public let minLevel: Level

        /// The destination's id, defaulting to the destination's type name concatenated with the log file's absolute
        /// URL.
        private(set) public lazy var id: String = "\(type(of: self))_\(fileURL.absoluteString)"

        /// The log file's URL.
        private let fileURL: URL

        /// The file manager.
        private let fileManager: FileManager

        /// The destination's synchronous queue.
        private let queue: Queue

        /// The destination's log metadata closure. When set, any time new metadata is set it will be converted into a
        /// message that is then written to the log gile. If `nil`, no metadata is logged.
        private let logMetadata: LogMetadataClosure?

        // MARK: - Lifecycle

        /// Creates a new instance of a log destination that outputs logs to a file.
        ///
        /// - Parameters:
        ///   - formatter: The log item formatter.
        ///   - fileURL: The destinations's log file URL.
        ///   - fileManager: The file manager to use for file system operations.
        ///   - minLevel: The minimum severity log level. Any item with a level below this level won't be logged. The
        /// default is `.error`.
        ///   - queue: The queue to perform asynchronous IO operations.
        ///   - logMetadata: The metadata logging closure. If non `nil`, any time new metadata is set it will be
        /// converted into a message that is then forwarded into the `output` closure and logged. Otherwise, no metadata
        /// is logged. The default is `nil` (no metadata logging).
        public init(formatter: ItemFormatter,
                    fileURL: URL,
                    fileManager: FileManager = .default,
                    minLevel: Level = .error,
                    queue: Queue = Queue(label: "com.mindera.alicerce.log.destination.file"),
                    logMetadata: LogMetadataClosure? = nil) {

            self.fileURL = fileURL
            self.fileManager = fileManager
            self.minLevel = minLevel
            self.formatter = formatter
            self.queue = queue
            self.logMetadata = logMetadata
        }

        // MARK: - Public Methods

        /// Clears the destination's log file, by deleting the file. The file is recreated on write if needed.
        ///
        /// - Throws: A `FileLogDestinationError.clearFailed` error if the file couldn't be cleared (removed).
        public func clear() throws {

            guard fileManager.fileExists(atPath: fileURL.path) else { return }

            do {
                try fileManager.removeItem(at: fileURL)
            }
            catch {
                throw FileLogDestinationError.clearFailed(fileURL, error)
            }
        }

        /// Writes a log item to the log file, after being successfully formatted by the item formatter.
        ///
        /// - Parameters:
        ///   - item: The item to write.
        ///   - onFailure: The closure to be invoked on failure (if the formatter or disk IO fail).
        public func write(item: Item, onFailure: @escaping (Error) -> Void) {

            queue.dispatchQueue.async { [unowned self] in

                let formattedLogItemData: Data
                do {
                    formattedLogItemData = try self.formatter.format(item: item)
                } catch {
                    return onFailure(FileLogDestinationError.itemFormatFailed(item, error))
                }

                guard !formattedLogItemData.isEmpty else { return }

                do {
                    try self.write(data: formattedLogItemData)
                } catch {
                    return onFailure(FileLogDestinationError.itemWriteFailed(self.fileURL, item, error))
                }
            }
        }

        /// Sets custom metadata by logging it to the console if `logMetadata` is **non nil**, to enrich existing log
        /// data (e.g. user info, device info, correlation ids, etc).
        ///
        /// This extra information can be very handy on its own, can and also be used to correlate logs between logging
        /// providers, for instance.
        ///
        /// - Parameters:
        ///   - metadata: The custom metadata to set.
        ///   - onFailure: The closure to be invoked on failure.
        public func setMetadata(_ metadata: [MetadataKey : Any], onFailure: @escaping (Error) -> Void) {

            guard let metadataData = logMetadata?(metadata), !metadataData.isEmpty else { return }

            queue.dispatchQueue.async { [unowned self] in
                do {
                    try self.write(data: metadataData)
                } catch {
                    return onFailure(FileLogDestinationError.metadataWriteFailed(self.fileURL,
                                                                                 metadata,
                                                                                 metadataData,
                                                                                 error))
                }
            }
        }

        /// This method has an empty implementation because metadata is logged to file, and thus can't easily be removed
        /// after being logged.
        ///
        /// - Parameters:
        ///   - keys: The custom metadata keys to remove.
        ///   - onFailure: The closure to be invoked on failure.
        public func removeMetadata(forKeys keys: [MetadataKey], onFailure: @escaping (Error) -> Void) {}

        /// Writes log data to the log file.
        ///
        /// - Parameter data: The data to write.
        /// - Throws: An error if the write fails, or the file handle can't be created.
        private func write(data: Data) throws {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return try data.write(to: fileURL)
            }

            let fileHandle = try FileHandle(forWritingTo: fileURL)

            fileHandle.seekToEndOfFile()
            fileHandle.write("\n".data(using: .utf8)! + data)
            fileHandle.closeFile()
        }
    }
}
