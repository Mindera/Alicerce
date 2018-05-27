import Alicerce

public enum MockStringLogDestinationError: Error {
    case itemFormatFailed(Log.Item, Error)
}

class MockLogDestination: LogDestination {

    typealias ErrorClosure = (Error) -> Void

    var writeInvokedClosure: ((Log.Item, @escaping ErrorClosure) -> Void)?
    var setMetadataInvokedClosure: (([AnyHashable : Any], @escaping ErrorClosure) -> Void)?
    var removeMetadataInvokedClosure: (([AnyHashable], @escaping ErrorClosure) -> Void)?

    var mockID: ID?
    var mockMinLevel: Log.Level?

    let defaultID: ID
    let defaultMinLevel: Log.Level

    // LogDestination

    var minLevel: Log.Level { return mockMinLevel ?? defaultMinLevel }
    var id: LogDestination.ID { return mockID ?? defaultID }

    // MARK: - Lifecycle

    public init(id: ID = "MockStringLogDestination", minLevel: Log.Level = .verbose) {
        self.defaultID = id
        self.defaultMinLevel = minLevel
    }

    // MARK: - Public methods

    public func write(item: Log.Item, onFailure: @escaping (Error) -> Void) {
        writeInvokedClosure?(item, onFailure)
    }

    func setMetadata(_ metadata: [AnyHashable : Any], onFailure: @escaping (Error) -> Void) {
        setMetadataInvokedClosure?(metadata, onFailure)
    }

    func removeMetadata(forKeys keys: [AnyHashable], onFailure: @escaping (Error) -> Void) {
        removeMetadataInvokedClosure?(keys, onFailure)
    }
}
