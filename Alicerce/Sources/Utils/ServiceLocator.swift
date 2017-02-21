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
    
    // MARK: - Public Methods
    
    func register<Service>(name serviceName: String? = nil, service: Service) throws {
        let name = buildName(for: Service.self, serviceName)
        
        try checkForDuplicateService(with: name)
        
        services[name] = service
    }
    
    func register<Service>(name serviceName: String? = nil, _ lazyInit: @escaping LazyServiceClosure<Service>) throws {
        let name = buildName(for: Service.self, serviceName)
        
        try checkForDuplicateService(with: name)
        
        lazyServiceInits[name] = lazyInit
    }
    
    func unregister<Service>(_: Service, name serviceName: String? = nil) throws {
        let name = buildName(for: Service.self, serviceName)
        
        guard let anyService = services[name] ?? lazyServiceInits[name]?() else {
            throw ServiceLocatorError.inexistentService
        }
        
        guard let _ = anyService as? Service else {
            throw ServiceLocatorError.serviceTypeMismatch(expected: "\(Service.self)", found: "\(type(of: anyService))")
        }
        
        services[name] = nil
        lazyServiceInits[name] = nil
    }
    
    func unregisterAll() {
        services.removeAll()
        lazyServiceInits.removeAll()
    }
    
    func get<Service>(name serviceName: String? = nil) throws -> Service {
        return try locate(serviceName)
    }
    
    // MARK: - Private Methods
    
    private func locate<Service>(_ serviceName: String? = nil) throws -> Service {
        let name = buildName(for: Service.self, serviceName)
        if let lazyServiceClosure = lazyServiceInits[name] {
            let service: Service = try checkIfServiceValid(lazyServiceClosure())
            
            // Remove closure since the service is now validated
            lazyServiceInits[name] = nil
            
            // This should *never* fail unless we have some name collision bug, so 💥 immediately
            try! register(name: name, service: service)
        }
        
        guard let anyService = services[name] else {
            throw ServiceLocatorError.inexistentService
        }
        
        return try checkIfServiceValid(anyService)
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
