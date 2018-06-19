import Foundation

public protocol ResourceParsePerformanceMetrics {

    var metrics: PerformanceMetrics { get }

    func parseIdentifier<R: Resource>(for resource: R, payload: String?) -> String
}

public class NetworkStoreParsePerformanceMetrics: ResourceParsePerformanceMetrics {

    public let metrics: PerformanceMetrics

    public func parseIdentifier<R: Resource>(for resource: R, payload: String?) -> String {
        return "Parse of \(R.Local.self)" + (payload ?? "")
    }

    public init(metrics: PerformanceMetrics) {
        self.metrics = metrics
    }
}
