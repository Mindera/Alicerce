//
//  ServiceLocator.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

public typealias LazyInit<Service> = () -> (Service)

public enum ServiceLocatorError: Error {
    case duplicateService(String)
    case duplicateLazyService(String)
    case inexistentService
    case serviceTypeMismatch(expected: String, found: String)
    case lazyServiceTypeMismatch(expected: String, found: String)
}

public final class ServiceLocator {

    static let sharedInstance = ServiceLocator()

    private var services = [String : Any]()
    private var lazyServiceInits = [String : Any]()

    private let lock = NSRecursiveLock()

    // MARK: - Public Methods
    
    func register<Service>(name serviceName: String? = nil, service: Service) throws {
        let name = buildName(for: Service.self, serviceName)

        try synchronized {
            try validateServiceName(name)

            services[name] = service
        }
    }

    func register<Service>(name serviceName: String? = nil, _ lazyInit: @escaping LazyInit<Service>) throws {
        let name = buildName(for: Service.self, serviceName)

        try synchronized {
            try validateServiceName(name)

            lazyServiceInits[name] = lazyInit
        }
    }

    func unregister<Service>(_ type: Service.Type, name serviceName: String? = nil) throws {
        let name = buildName(for: type, serviceName)

        try synchronized {
            if let service = services[name] {
                assert(lazyServiceInits[name] == nil, "💥: Uninitialized Lazy Service exists with name: \(name)!")

                let _: Service = try validateServiceType(service)

                services[name] = nil
            } else if let anyServiceInit = lazyServiceInits[name] {

                // don't call `validateLazyServiceType` to avoid initialising the service without need
                guard let _ = anyServiceInit as? LazyInit<Service> else {
                    throw ServiceLocatorError.lazyServiceTypeMismatch(expected: "\(LazyInit<Service>.self)",
                                                                      found: "\(type(of: anyServiceInit))")
                }

                lazyServiceInits[name] = nil
            } else {
                throw ServiceLocatorError.inexistentService
            }
        }
    }

    func unregisterAll() {
        synchronized {
            services.removeAll()
            lazyServiceInits.removeAll()
        }
    }

    func get<Service>(name serviceName: String? = nil) throws -> Service {
        let name = buildName(for: Service.self, serviceName)
        var service: Service?

        try synchronized {
            service = try locate(name)
        }

        // This should *never* fail unless we have some bug returning the service, so 💥 immediately
        return service!
    }

    // MARK: - Private Methods

    private func locate<Service>(_ name: String) throws -> Service {
        if let lazyServiceClosure = lazyServiceInits[name] {
            let service: Service = try validateLazyServiceType(lazyServiceClosure)

            // Remove closure since the service is now validated
            lazyServiceInits[name] = nil

            assert(services[name] == nil, "💥: Service already exists with name: \(name)!")
            services[name] = service
            return service
        }

        guard let anyService = services[name] else {
            throw ServiceLocatorError.inexistentService
        }

        return try validateServiceType(anyService)
    }

    private func buildName<Service>(`for` _: Service.Type, _ serviceName: String? = nil) -> String {
        return serviceName ?? "\(Service.self)"
    }

    private func validateServiceType<Service>(_ anyService: Any) throws -> Service {
        guard let service = anyService as? Service else {
            throw ServiceLocatorError.serviceTypeMismatch(expected: "\(Service.self)", found: "\(type(of: anyService))")
        }

        return service
    }

    private func validateLazyServiceType<Service>(_ anyServiceClosure: Any) throws -> Service {
        guard let serviceClosure = anyServiceClosure as? LazyInit<Service> else {
            throw ServiceLocatorError.lazyServiceTypeMismatch(expected: "\(LazyInit<Service>.self)",
                                                              found: "\(type(of: anyServiceClosure))")
        }

        return serviceClosure()
    }

    private func validateServiceName(_ name: String) throws {
        guard services[name] == nil else {
            throw ServiceLocatorError.duplicateService(name)
        }
        
        guard lazyServiceInits[name] == nil else {
            throw ServiceLocatorError.duplicateLazyService(name)
        }
    }

    private func synchronized(_ criticalSection: () throws -> ()) rethrows {
        defer { lock.unlock() }
        lock.lock()
        try criticalSection()
    }
}
