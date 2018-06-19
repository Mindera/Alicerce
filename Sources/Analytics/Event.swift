import Foundation

public extension Analytics {
    
    /// The Event oject
    /// Contains the name and all the necessary parameters for tracking
    public struct Event {
        public let name: String
        public let parameters: Parameters?
        
        public init(name: String, parameters: Parameters? = nil) {
            self.name = name
            self.parameters = parameters
        }
    }
}

extension Analytics.Event: Equatable {
    public static func ==(lhs: Analytics.Event, rhs: Analytics.Event) -> Bool {
        return (lhs.name == rhs.name) &&
            ((lhs.parameters == nil && rhs.parameters == nil) || lhs.parameters?.count == rhs.parameters?.count)
    }
}
