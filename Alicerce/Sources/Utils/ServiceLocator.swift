//
//  ServiceLocator.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

public typealias ServiceName = String

public enum ServiceLocatorError: Error {
    case duplicateService(ServiceName)
    case duplicateLazyService(ServiceName)
    case inexistentService
    case serviceTypeMismatch(expected: Any.Type, found: Any.Type)
    case lazyServiceTypeMismatch(expected: Any.Type, found: Any.Type)
}

public final class ServiceLocator {

    public typealias LazyInit<Service> = () -> (Service)

    private enum RegisteredService {
        case normal(Any)
        case lazy(Any)
    }

    static let sharedInstance = ServiceLocator()

    private var services = [ServiceName : RegisteredService]()

    private let lock = NSRecursiveLock()

    // MARK: - Public Methods

    @discardableResult
    func register<Service>(name serviceName: ServiceName? = nil, service: Service) throws -> ServiceName {
        let name = buildName(for: Service.self, serviceName)

        try synchronized {
            try validate(serviceName: name)
            services[name] = .normal(service)
        }

        return name
    }

    @discardableResult
    func register<Service>(name serviceName: ServiceName? = nil,
                           _ lazyInit: @escaping LazyInit<Service>) throws -> ServiceName {
        let name = buildName(for: Service.self, serviceName)

        try synchronized {
            try validate(serviceName: name)
            services[name] = .lazy(lazyInit)
        }

        return name
    }

    func unregister<Service>(_ type: Service.Type, name serviceName: ServiceName? = nil) throws {
        let name = buildName(for: type, serviceName)

        try synchronized {
            guard let registeredService = services[name] else { throw ServiceLocatorError.inexistentService }

            try validate(serviceType: type, registeredService: registeredService)
            services[name] = nil
        }
    }

    func unregisterAll() {
        synchronized {
            services.removeAll()
        }
    }

    func get<Service>(name serviceName: ServiceName? = nil) throws -> Service {
        let name = buildName(for: Service.self, serviceName)
        var service: Service! // this will *always* contain a value if no error occurs, hence the `!` 💪

        try synchronized {
            guard let registeredService = services[name] else { throw ServiceLocatorError.inexistentService }

            switch registeredService {
            case let .normal(anyService):
                service = try validateTypeAndReturn(service: anyService)
            case let .lazy(anyServiceInit):
                service = try validateTypeAndReturn(lazyInit: anyServiceInit)
                services[name] = .normal(service)
            }
        }

        return service
    }

    // MARK: - Private Methods

    private func locate<Service>(_ name: ServiceName) throws -> Service {
        guard let service = services[name] else { throw ServiceLocatorError.inexistentService }

        switch service {
        case let .normal(anyService):
            return try validateTypeAndReturn(service: anyService)
        case let .lazy(anyServiceInit):
            let service: Service = try validateTypeAndReturn(lazyInit: anyServiceInit)
            services[name] = .normal(service)
            return service
        }
    }

    private func buildName<Service>(`for` _: Service.Type, _ serviceName: ServiceName? = nil) -> ServiceName {
        return serviceName ?? "\(Service.self)"
    }

    // MARK: Validations

    private func validateTypeAndReturn<Service>(service anyService: Any) throws -> Service {
        guard let service = anyService as? Service else {
            throw ServiceLocatorError.serviceTypeMismatch(expected: Service.self, found: type(of: anyService))
        }

        return service
    }

    private func validateTypeAndReturn<Service>(lazyInit anyServiceInit: Any) throws -> Service {
        guard let serviceClosure = anyServiceInit as? LazyInit<Service> else {
            throw ServiceLocatorError.lazyServiceTypeMismatch(expected: LazyInit<Service>.self,
                                                              found: type(of: anyServiceInit))
        }

        return serviceClosure()
    }

    private func validate<Service>(serviceType type: Service.Type, registeredService: RegisteredService) throws {
        // avoid returning (and initialising) the service if not needed (e.g. when unregistering)

        switch registeredService {
        case let .normal(anyService):
            guard let _ = anyService as? Service else {
                throw ServiceLocatorError.serviceTypeMismatch(expected: Service.self, found: type(of: anyService))
            }
        case let .lazy(anyServiceInit):
            guard let _ = anyServiceInit as? LazyInit<Service> else {
                throw ServiceLocatorError.lazyServiceTypeMismatch(expected: LazyInit<Service>.self,
                                                                  found: type(of: anyServiceInit))
            }
        }
    }

    private func validate(serviceName: ServiceName) throws {
        guard let registeredService = services[serviceName] else { return }

        switch registeredService {
        case .normal: throw ServiceLocatorError.duplicateService(serviceName)
        case .lazy: throw ServiceLocatorError.duplicateLazyService(serviceName)
        }
    }

    // MARK: Synchronisation

    private func synchronized(_ criticalSection: () throws -> ()) rethrows {
        defer { lock.unlock() }
        lock.lock()
        try criticalSection()
    }
}
