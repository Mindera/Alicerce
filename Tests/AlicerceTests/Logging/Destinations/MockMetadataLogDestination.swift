import Alicerce

typealias MockLogDestination = MockMetadataLogDestination<Log.NoModule, Log.NoMetadataKey>

class MockMetadataLogDestination<Module: LogModule, MetadataKey: Hashable>: MetadataLogDestination {

    typealias ErrorClosure = (Error) -> Void

    var writeInvokedClosure: ((Log.Item, @escaping ErrorClosure) -> Void)?

    var setMetadataInvokedClosure: (([MetadataKey : Any], @escaping ErrorClosure) -> Void)?
    var removeMetadataInvokedClosure: (([MetadataKey], @escaping ErrorClosure) -> Void)?

    var registerModuleInvokedClosure: ((Module, Log.Level) -> Void)?
    var unregisterModuleInvokedClosure: ((Module) -> Void)?

    var mockMinLevel: Log.Level = .verbose

    // LogDestination

    var minLevel: Log.Level { mockMinLevel }

    let id: UUID

    // MARK: - Lifecycle

    public init(id: UUID = .init(), mockMinLevel: Log.Level = .verbose) {

        self.id = id
        self.mockMinLevel = mockMinLevel
    }

    // MARK: - Public methods

    public func write(item: Log.Item, onFailure: @escaping (Error) -> Void) {

        writeInvokedClosure?(item, onFailure)
    }

    func setMetadata(_ metadata: [MetadataKey : Any], onFailure: @escaping (Error) -> Void) {

        setMetadataInvokedClosure?(metadata, onFailure)
    }

    func removeMetadata(forKeys keys: [MetadataKey], onFailure: @escaping (Error) -> Void) {

        removeMetadataInvokedClosure?(keys, onFailure)
    }
}

extension MockMetadataLogDestination: MetadataLogger {}

extension MockMetadataLogDestination: ModuleLogger {

    func registerModule(_ module: Module, minLevel: Log.Level) throws {

        registerModuleInvokedClosure?(module, minLevel)
    }

    func unregisterModule(_ module: Module) throws {

        unregisterModuleInvokedClosure?(module)
    }
}
