//
//  AnalyticsTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class AnalyticsTestCase: XCTestCase {
    
    final class TestableTracker: AnalyticsTracker {
        private let expectation: XCTestExpectation
        
        var mockPage: Analytics.Page
        var mockEvent: Analytics.Event
        
        init(expectation: XCTestExpectation,
             page: Analytics.Page = Analytics.Page(name: "page", parameters: nil),
             event: Analytics.Event = Analytics.Event(name: "event", parameters: nil)) {
            
            self.expectation = expectation
            self.mockPage = page
            self.mockEvent = event
        }
        
        func track(page: Analytics.Page) {
            XCTAssertEqual(page, mockPage)
            
            expectation.fulfill()
        }
        
        func track(event: Analytics.Event) {
            XCTAssertEqual(event, mockEvent)
            
            expectation.fulfill()
        }
    }
    
    func testAddParameters_WithACleanListOfParameters_ItShouldAppendTheNewParameters() {
        let analytics = Analytics()
        
        XCTAssertNil(analytics.parameters)
        
        analytics.add(parameters: ["1" : "1"])
        
        XCTAssertNotNil(analytics.parameters)
        XCTAssertNotNil(analytics.parameters?.first)
        XCTAssertEqual(analytics.parameters?.count, 1)
        let firstParameter = analytics.parameters?.first
        XCTAssertEqual(firstParameter?.key, "1")
        XCTAssertEqual(firstParameter?.value as! String, "1")
    }
    
    func testAddParameters_WithADirtyList_ItShouldAppendTheNewParameters() {
        let analyticsConfiguration = Analytics.Configuration(extraParameters: [
            "1" : "1"
        ])
        
        let analytics = Analytics(configuration: analyticsConfiguration)
        
        XCTAssertNotNil(analytics.parameters)
        XCTAssertEqual(analytics.parameters?.count, 1)
        
        analytics.add(parameters: ["2" : "2"])
        
        XCTAssertEqual(analytics.parameters?.count, 2)
        XCTAssertEqual(analytics.parameters!["1"] as! String, "1")
        XCTAssertEqual(analytics.parameters!["2"] as! String, "2")
    }
    
    func testAddTracker_WhenATrackerIsAdded_ItShouldSendEventsToThatTracker() {
        let expectation = self.expectation(description: "Track appended tracker")

        let page = Analytics.Page(name: "trackPage", parameters: nil)
        let testableTracker = TestableTracker(expectation: expectation, page: page)
        
        let analytics = Analytics()
        analytics.add(tracker: testableTracker)
        
        analytics.track(page: page)
        
        waitForExpectations(timeout: 30)
    }
    
    func testTrackPage_WithoutGlobalParameters_ItShouldMatchTheOriginalPage() {
        let expectation = self.expectation(description: "Track page to the testable tracker")
        
        let page = Analytics.Page(name: "trackablePage", parameters: ["1" : "1"])
        let tracker = TestableTracker(expectation: expectation, page: page)
        
        let analytics = Analytics()
        analytics.add(tracker: tracker)
        
        analytics.track(page: page)
        
        waitForExpectations(timeout: 30)
    }
    
    func testTrackPage_WithGlobalParameters_ItShouldMatchAPageWithMoreParameters() {
        let expectation = self.expectation(description: "Track page to the testable tracker")
        
        let trackerPage = Analytics.Page(name: "trackablePage", parameters: ["1" : "1", "2" : "2"])
        let tracker = TestableTracker(expectation: expectation, page: trackerPage)
        
        let analyticsConfiguration = Analytics.Configuration(extraParameters: [
            "1" : "1"
            ])
        
        let analytics = Analytics(configuration: analyticsConfiguration)
        analytics.add(tracker: tracker)
        
        let page = Analytics.Page(name: "trackablePage", parameters: ["2" : "2"])
        analytics.track(page: page)
        
        waitForExpectations(timeout: 30)
    }
    
    func testTrackEvent_WithoutGlobalParameters_ItShouldMatchOriginalEvent() {
        let expectation = self.expectation(description: "Track page to the testable tracker")
        
        let event = Analytics.Event(name: "trackableEvent", parameters: ["1" : "1"])
        let tracker = TestableTracker(expectation: expectation, event: event)
        
        let analytics = Analytics()
        analytics.add(tracker: tracker)
        
        analytics.track(event: event)
        
        waitForExpectations(timeout: 30)
    }
    
    func testTrackEvent_WithGlobalParameters_ItShouldMatchAnEventWithMoreParameters() {
        let expectation = self.expectation(description: "Track page to the testable tracker")
        
        let trackerEvent = Analytics.Event(name: "trackableEvent", parameters: ["1" : "1", "2" : "2"])
        let tracker = TestableTracker(expectation: expectation, event: trackerEvent)
        
        let analyticsConfiguration = Analytics.Configuration(extraParameters: [
            "1" : "1"
            ])
        
        let analytics = Analytics(configuration: analyticsConfiguration)
        analytics.add(tracker: tracker)
        
        let event = Analytics.Event(name: "trackableEvent", parameters: ["2" : "2"])
        analytics.track(event: event)
        
        waitForExpectations(timeout: 30)
    }
}
