import Foundation

#if swift(>=5.1)
@propertyWrapper
public struct Locate<Service> {
    private var service: Service
    public init(name: String? = nil, locator: ServiceLocator = .shared) {
        do {
            self.service = try locator.get(name: name)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    public var wrappedValue: Service {
        get { return service }
        mutating set { service = newValue }
    }
    public var projectedValue: Locate<Service> {
        get { return self }
        mutating set { self = newValue }
    }
}
#endif
