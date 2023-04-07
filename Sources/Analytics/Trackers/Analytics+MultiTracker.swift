import Foundation

#if canImport(AlicerceCore)
import AlicerceCore
#endif

public extension Analytics {

    /// An analytics tracker that forwards analytics events to multiple trackers, while not doing any tracking on its
    /// own.
    final class MultiTracker<State, Action, ParameterKey: AnalyticsParameterKey>: AnalyticsTracker {

        /// The registered sub trackers.
        public let trackers: [AnyAnalyticsTracker<State, Action, ParameterKey>]

        /// Creates an analytics multi tracker instance.
        /// - Parameter trackers: The analytics trackers to register.
        public init(trackers: [AnyAnalyticsTracker<State, Action, ParameterKey>]) {

            assert(!trackers.isEmpty, "🙅‍♂️ Trackers shouldn't be empty, since it renders this tracker useless!")

            self.trackers = trackers
        }

        /// Creates an analytics multi tracker instance.
        /// - Parameter trackers: The result builder that outputs the analytics trackers to register.
        public init(@TrackerBuilder trackers: () -> [AnyAnalyticsTracker<State, Action, ParameterKey>]) {

            self.trackers = trackers()

            assert(!self.trackers.isEmpty, "🙅‍♂️ Trackers shouldn't be empty, since it renders this tracker useless!")
        }

        // MARK: - Tracking

        /// Tracks an analytics event, by propagating it to all the registered sub trackers.
        ///
        /// - Parameter event: The event to track.
        public func track(_ event: Analytics.Event<State, Action, ParameterKey>) {

            trackers.forEach { $0.track(event) }
        }
    }
}

extension Analytics.MultiTracker {

    @resultBuilder
    public struct TrackerBuilder {

        public typealias AnyAnalyticsTracker = Analytics.AnyAnalyticsTracker<State, Action, ParameterKey>

        public static func buildExpression<Tracker: AnalyticsTracker>(_ tracker: Tracker) -> [AnyAnalyticsTracker]
        where Tracker.State == State, Tracker.Action == Action, Tracker.ParameterKey == ParameterKey {

            [tracker.eraseToAnyAnalyticsTracker()]
        }

        public static func buildExpression(_ tracker: AnyAnalyticsTracker) -> [AnyAnalyticsTracker] { [tracker] }

        public static func buildExpression(_ trackers: [AnyAnalyticsTracker]) -> [AnyAnalyticsTracker] { trackers }

        public static func buildBlock(_ trackers: [AnyAnalyticsTracker]...) -> [AnyAnalyticsTracker] {

            trackers.flatMap { $0 }
        }

        public static func buildOptional(_ tracker: [AnyAnalyticsTracker]?) -> [AnyAnalyticsTracker] { tracker ?? [] }

        public static func buildEither(first tracker: [AnyAnalyticsTracker]) -> [AnyAnalyticsTracker] { tracker }

        public static func buildEither(second tracker: [AnyAnalyticsTracker]) -> [AnyAnalyticsTracker] { tracker }

        public static func buildLimitedAvailability(_ tracker: [AnyAnalyticsTracker]) -> [AnyAnalyticsTracker] {

            tracker
        }

        public static func buildArray(_ trackers: [[AnyAnalyticsTracker]]) -> [AnyAnalyticsTracker] {

            trackers.flatMap { $0 }
        }
    }
}
