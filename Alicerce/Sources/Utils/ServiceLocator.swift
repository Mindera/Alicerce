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
    
    func register<Service>(service: Service, serviceName: String? = nil) throws {
        let name = buildName(for: Service.self, serviceName)
        
        try checkForDuplicatedService(for: name)
        
        services[name] = service
    }
    
    func register<Service>(serviceName: String? = nil, _ lazyInit: @escaping LazyServiceClosure<Service>) throws {
        let name = buildName(for: Service.self, serviceName)
        
        try checkForDuplicatedService(for: name)
        
        lazyServices[name] = lazyInit
    }
    
    func unregister<Service>(_: Service, serviceName: String? = nil) throws {
        let _: Service = try locate(serviceName)
        
        let name = buildName(for: Service.self, serviceName)
        services[name] = nil
    }
    
    func unregisterAll() {
        services.removeAll()
    }
    
    func get<Service>(serviceName: String? = nil) throws -> Service {
        return try locate(serviceName)
    }
    
    // MARK: - Private Methods
    
    private func locate<Service>(_ serviceName: String? = nil) throws -> Service {
        let name = buildName(for: Service.self, serviceName)
        if let lazyServiceClosure = lazyServices[name] {
            // Remove closure since this is already initialised
            lazyServices[name] = nil
            
            let service: Service = try checkIfServiceValid(lazyServiceClosure())
            
            try register(service: service)
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
            throw ServiceLocatorError.serviceTypeMismatch
        }
        
        return service
    }
    
    private func checkForDuplicatedService(`for` name: String) throws {
        guard services[name] == nil else {
            throw ServiceLocatorError.lazyDuplicatedService(name)
        }
    }
}
