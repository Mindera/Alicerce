import Foundation

/// Analytics allows you to track pages or events to all the registered trackers.
/// Registered trackers should implement the `AnalyticsTracker` protocol.
/// For every track, the parameters sent with the `Page` or `Event` are merged with global parameters.
public final class Analytics {
    
    /// Typealias for a dictionary with `String` as key and with `Any` value
    public typealias Parameters = [String : Any]
    
    public var parameters: Parameters? { return extraParameters }
    
    fileprivate lazy var trackers = [AnalyticsTracker]()
    
    fileprivate let trackingQueue: DispatchQueue
    
    fileprivate var extraParameters: Parameters?
    
    /// Creates an analytics instance with provided configuration
    ///
    /// - Parameter configuration: A Configuration object with QoS and extraParameters (if any)
    public init(configuration: Configuration = Configuration()) {
        self.trackingQueue = DispatchQueue(label: "com.mindera.alicerce.queue.analytics.tracking",
                                           qos: configuration.queueQoS)
        self.extraParameters = configuration.extraParameters
    }
    
    // MARK: - Public Methods
    
    /// Appends a new parameter into the extraParameters.
    /// Those are appended with tracking item when a track is called.
    ///
    /// - Parameter parameters: A dictionary with a String and Any
    public func add(parameters: Parameters) {
        extraParameters = merge(parameters: parameters, withExtraParameters: extraParameters)
    }
    
    /// Appends a tracker into the trackers.
    /// This is responsible to send this values to the specific platform
    ///
    /// - Parameter tracker: An AnalyticsTracker object
    public func add(tracker: AnalyticsTracker) {
        trackers.append(tracker)
    }
}

extension Analytics: AnalyticsTracker {
    public func track(page: Page) {
        let trackersCopy = trackers
        let parameters = merge(parameters: page.parameters, withExtraParameters: extraParameters)
        
        trackingQueue.async {
            let newPage = Page(name: page.name, parameters: parameters)
            
            trackersCopy.forEach {
                $0.track(page: newPage)
            }
        }
    }
    
    public func track(event: Event) {
        let trackersCopy = trackers
        let parameters = merge(parameters: event.parameters, withExtraParameters: extraParameters)
        
        trackingQueue.async {
            let newEvent = Event(name: event.name, parameters: parameters)
            
            trackersCopy.forEach {
                $0.track(event: newEvent)
            }
        }
    }
}

private func merge(parameters: Analytics.Parameters?,
                   withExtraParameters extra: Analytics.Parameters?) -> Analytics.Parameters? {
    
    switch (parameters, extra) {
    case (var parameters?, let extra?):
        parameters.merge(extra, uniquingKeysWith: { _, new in new })
        return parameters
    default:
        return parameters ?? extra
    }
}
