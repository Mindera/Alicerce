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
    case serviceTypeMismatch
    case lazyDuplicatedService(String)
}

public final class ServiceLocator {
    
    static let sharedInstance = ServiceLocator()
    
    private var services = [String : Any]()
    private lazy var lazyServices = [String : LazyServiceClosure<Any>]()
    
    // MARK: - Public Methods
    
    func register<Service>(service: Service, serviceName: String? = nil) throws {
        let name = buildName(for: Service.self, serviceName)
        
        try register(service: service, name: name)
    }
    
    func register<Service>(serviceName: String? = nil, _ lazyInit: @escaping LazyServiceClosure<Service>) throws {
        let name = buildName(for: Service.self, serviceName)
        
        try register(serviceName: name, lazyInit)
    }
    
    func unregister<Service>(_: Service, serviceName: String? = nil) throws {
        let name = buildName(for: Service.self, serviceName)
        
        services[name] = nil
        lazyServices[name] = nil
    }
    
    func unregisterAll() {
        services.removeAll()
        lazyServices.removeAll()
    }
    
    func get<Service>(serviceName: String? = nil) throws -> Service {
        let name = buildName(for: Service.self, serviceName)
        
        return try locateAndRegister(serviceName: name)
    }
    
    // MARK: - Private Methods
    
    private func register<Service>(service: Service, name: String) throws {
        try checkForDuplicatedService(for: name)
        
        services[name] = service
    }
    
    private func register<Service>(serviceName: String, _ lazyInit: @escaping LazyServiceClosure<Service>) throws {
        try checkForDuplicatedService(for: serviceName)
        
        lazyServices[serviceName] = lazyInit
    }
    
    private func locateAndRegister<Service>(serviceName: String) throws -> Service {
        if let lazyServiceClosure = lazyServices[serviceName] {
            // Remove closure since this is already initialised
            lazyServices[serviceName] = nil
            
            let service: Service = try checkIfServiceValid(lazyServiceClosure())
            
            try register(service: service, name: serviceName)
        }
        
        return try locate(serviceName: serviceName)
    }
    
    private func locate<Service>(serviceName: String) throws -> Service {
        guard let anyService = services[serviceName] else {
            throw ServiceLocatorError.inexistentService
        }
        
        return try checkIfServiceValid(anyService)
    }
    
    private func buildName<Service>(`for` _: Service.Type, _ serviceName: String? = nil) -> String {
        return serviceName ?? "\(Service.self)"
    }
    
    private func checkIfServiceValid<Service>(_ anyService: Any) throws -> Service {
        guard let service = anyService as? Service else {
            throw ServiceLocatorError.serviceTypeMismatch
        }
        
        return service
    }
    
    private func checkForDuplicatedService(`for` name: String) throws {
        guard services[name] == nil else {
            throw ServiceLocatorError.duplicateService(name)
        }
        
        guard services[name] == nil else {
            throw ServiceLocatorError.lazyDuplicatedService(name)
        }
    }
}
