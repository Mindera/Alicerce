import Foundation

public extension Analytics {
    
    /// A Page object
    /// Contains the name and all the necessary parameters for tracking
    public struct Page {
        public let name: String
        public let parameters: Parameters?
        
        public init(name: String, parameters: Parameters? = nil) {
            self.name = name
            self.parameters = parameters
        }
    }
}

extension Analytics.Page: Equatable {
    public static func ==(lhs: Analytics.Page, rhs: Analytics.Page) -> Bool {
        return (lhs.name == rhs.name) &&
            ((lhs.parameters == nil && rhs.parameters == nil) || lhs.parameters?.count == rhs.parameters?.count)
    }
}
