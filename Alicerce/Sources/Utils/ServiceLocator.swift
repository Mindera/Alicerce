//
//  ServiceLocator.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

public typealias LazyServiceClosure<Service> = () -> (Service)

public enum ServiceLocatorError: Error {
    case duplicateService(String)
    case inexistentService
    case serviceTypeMismatch(expected: String, found: String)
    case duplicateLazyServiceInit(String)
}

public final class ServiceLocator {

    static let sharedInstance = ServiceLocator()

    private var services = [String : Any]()
    private var lazyServiceInits = [String : LazyServiceClosure<Any>]()

    private let queue: DispatchQueue

    // MARK: - Initializers

    init(queueQoS: DispatchQoS = .default) {
        queue = DispatchQueue(label: "com.mindera.\(type(of: self)).queue", qos: queueQoS)
    }

    // MARK: - Public Methods
    
    func register<Service>(name serviceName: String? = nil, service: Service) throws {
        let name = buildName(for: Service.self, serviceName)

        try queue.sync { [unowned self] in
            try self.checkForDuplicateService(with: name)

            self.services[name] = service
        }
    }

    func register<Service>(name serviceName: String? = nil, _ lazyInit: @escaping LazyServiceClosure<Service>) throws {
        let name = buildName(for: Service.self, serviceName)

        try queue.sync { [unowned self] in
            try self.checkForDuplicateService(with: name)

            self.lazyServiceInits[name] = lazyInit
        }
    }

    func unregister<Service>(_: Service, name serviceName: String? = nil) throws {
        let name = buildName(for: Service.self, serviceName)

        try queue.sync { [unowned self] in
            guard let anyService = self.services[name] ?? self.lazyServiceInits[name]?() else {
                throw ServiceLocatorError.inexistentService
            }

            guard let _ = anyService as? Service else {
                throw ServiceLocatorError.serviceTypeMismatch(expected: "\(Service.self)", found: "\(type(of: anyService))")
            }

            self.services[name] = nil
            self.lazyServiceInits[name] = nil
        }
    }

    func unregisterAll() {
        queue.sync { [unowned self] in
            self.services.removeAll()
            self.lazyServiceInits.removeAll()
        }
    }

    func get<Service>(name serviceName: String? = nil) throws -> Service {
        let name = buildName(for: Service.self, serviceName)
        var service: Service?

        try queue.sync { [unowned self] in
            service = try self.locate(name)
        }

        // This should *never* fail unless we have some bug returning the service, so 💥 immediately
        return service!
    }

    // MARK: - Private Methods

    private func locate<Service>(_ name: String) throws -> Service {
        if let lazyServiceClosure = lazyServiceInits[name] {
            let service: Service = try checkIfServiceValid(lazyServiceClosure())

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

    private func checkIfServiceValid<Service>(_ anyService: Any) throws -> Service {
        guard let service = anyService as? Service else {
            throw ServiceLocatorError.serviceTypeMismatch(expected: "\(Service.self)", found: "\(type(of: anyService))")
        }

        return service
    }

    private func checkForDuplicateService(with name: String) throws {
        guard services[name] == nil else {
            throw ServiceLocatorError.duplicateService(name)
        }
        
        guard lazyServiceInits[name] == nil else {
            throw ServiceLocatorError.duplicateLazyServiceInit(name)
        }
    }
}
