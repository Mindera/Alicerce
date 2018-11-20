import Foundation

public final class ServiceLocator {

    public enum Error: Swift.Error {
        case duplicateService(ServiceName)
        case duplicateLazyService(ServiceName)
        case inexistentService
        case serviceTypeMismatch(expected: Any.Type, found: Any.Type)
        case lazyServiceTypeMismatch(expected: Any.Type, found: Any.Type)
    }

    public typealias ServiceName = String
    public typealias LazyInit<Service> = () -> (Service)

    private enum RegisteredService {
        case normal(Any)
        case lazy(Any)
    }

    public static let shared = ServiceLocator()

    private var services = [ServiceName : RegisteredService]()

    private let lock = NSRecursiveLock()

    // MARK: - Public Methods

    @discardableResult
    public func register<Service>(name serviceName: ServiceName? = nil, service: Service) throws -> ServiceName {
        let name = buildName(for: Service.self, serviceName)

        try synchronized {
            try validate(serviceName: name)
            services[name] = .normal(service)
        }

        return name
    }

    @discardableResult
    public func register<Service>(name serviceName: ServiceName? = nil,
                                  lazyService lazyInit: @escaping LazyInit<Service>) throws -> ServiceName {
        let name = buildName(for: Service.self, serviceName)

        try synchronized {
            try validate(serviceName: name)
            services[name] = .lazy(lazyInit)
        }

        return name
    }

    public func unregister<Service>(_ type: Service.Type, name serviceName: ServiceName? = nil) throws {
        let name = buildName(for: type, serviceName)

        try synchronized {
            guard let registeredService = services[name] else { throw Error.inexistentService }

            try validate(serviceType: type, registeredService: registeredService)
            services[name] = nil
        }
    }

    public func unregisterAll() {
        synchronized {
            services.removeAll()
        }
    }

    public func get<Service>(name serviceName: ServiceName? = nil) throws -> Service {
        let name = buildName(for: Service.self, serviceName)

        return try synchronized {
            guard let registeredService = services[name] else { throw Error.inexistentService }

            switch registeredService {
            case let .normal(anyService):
                return try validateTypeAndReturn(service: anyService)
            case let .lazy(anyServiceInit):
                let service: Service = try validateTypeAndReturn(lazyInit: anyServiceInit)
                services[name] = .normal(service)
                return service
            }
        }
    }

    // MARK: - Private Methods

    private func buildName<Service>(`for` _: Service.Type, _ serviceName: ServiceName? = nil) -> ServiceName {
        return serviceName ?? "\(Service.self)"
    }

    // MARK: Validations

    private func validateTypeAndReturn<Service>(service anyService: Any) throws -> Service {
        guard let service = anyService as? Service else {
            throw Error.serviceTypeMismatch(expected: Service.self, found: type(of: anyService))
        }

        return service
    }

    private func validateTypeAndReturn<Service>(lazyInit anyServiceInit: Any) throws -> Service {
        guard let serviceClosure = anyServiceInit as? LazyInit<Service> else {
            throw Error.lazyServiceTypeMismatch(expected: LazyInit<Service>.self, found: type(of: anyServiceInit))
        }

        return serviceClosure()
    }

    private func validate<Service>(serviceType type: Service.Type, registeredService: RegisteredService) throws {
        // avoid returning (and initialising) the service if not needed (e.g. when unregistering)

        switch registeredService {
        case let .normal(anyService):
            guard let _ = anyService as? Service else {
                throw Error.serviceTypeMismatch(expected: Service.self, found: Swift.type(of: anyService))
            }
        case let .lazy(anyServiceInit):
            guard let _ = anyServiceInit as? LazyInit<Service> else {
                throw Error.lazyServiceTypeMismatch(expected: LazyInit<Service>.self,
                                                    found: Swift.type(of: anyServiceInit))
            }
        }
    }

    private func validate(serviceName: ServiceName) throws {
        guard let registeredService = services[serviceName] else { return }

        switch registeredService {
        case .normal: throw Error.duplicateService(serviceName)
        case .lazy: throw Error.duplicateLazyService(serviceName)
        }
    }

    // MARK: Synchronisation

    private func synchronized<T>(_ criticalSection: () throws -> T) rethrows -> T {
        defer { lock.unlock() }
        lock.lock()
        return try criticalSection()
    }
}
