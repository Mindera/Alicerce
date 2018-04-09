//
//  ResourceTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 09/04/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class ResourceTestCase: XCTestCase {

    // MARK: - StaticNetworkResource

    func testStaticNetworkResource_WithoutQueryItemsOnPathAndNoQueryItems_ItShouldReturnTheSameURL() {
        let url = URL(string: "http://test.com/somepath/")!
        let resource = MockStaticNetworkResource(url: url)

        let builtRequest = resource.request

        XCTAssertNotNil(builtRequest.url)
        XCTAssertEqual(builtRequest.url, url, "💥 the URLs should be the same")
    }

    func testStaticNetworkResource_WithQueryItemsOnPathAndNoQueryItems_ItShouldReturnTheSameURL() {
        let url = URL(string: "http://test.com/somepath/?item1=one&item2=two")!
        let resource = MockStaticNetworkResource(url: url)

        let builtRequest = resource.request

        XCTAssertNotNil(builtRequest.url)
        XCTAssertEqual(builtRequest.url, url, "💥 the URLs should be the same")
    }

    func testStaticNetworkResource_WithoutQueryItemsOnPathAndQueryItems_ItShouldReturnTheURLWithTheQueryItems() {
        let url = URL(string: "http://test.com/somepath/")!
        let resource = MockStaticNetworkResource(url: url, query: ["item1" : "one", "item2" : "two"])

        let builtRequest = resource.request

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = resource.query.flatMap { $0.map { URLQueryItem(name: $0, value: $1) } }

        let builtURL = components.url!

        XCTAssertNotNil(builtRequest.url)
        XCTAssertEqual(builtRequest.url, builtURL, "💥 the URLs should be the same")
    }

    func testStaticNetworkResource_WithQueryItemsOnPathAndQueryItems_ItShouldReturnTheURLWithBothQueryItems() {
        let url = URL(string: "http://test.com/somepath/?item1=one&item2=two")!
        let resource = MockStaticNetworkResource(url: url, query: ["item3" : "three", "item4" : "four"])

        let builtRequest = resource.request

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = components.queryItems! + resource.query.flatMap { $0.map { URLQueryItem(name: $0, value: $1) } }!

        let builtURL = components.url!

        XCTAssertNotNil(builtRequest.url)
        XCTAssertEqual(builtRequest.url, builtURL, "💥 the URLs should be the same")
    }
}

private enum NoError: Swift.Error { case empty }

private struct MockStaticNetworkResource: StaticNetworkResource {
    static var empty: Void = ()

    let parse: ResourceMapClosure<Void, Void> = { _ in XCTFail("💥 How was this possible? 😳") }
    let serialize: ResourceMapClosure<Void, Void> = { _ in XCTFail("💥 How was this possible? 😳") }
    let errorParser: ResourceErrorParseClosure<Void, NoError> = { _ in XCTFail("💥 How was this possible? 😳"); return NoError.empty }

    let url: URL
    let headers: HTTP.Headers?
    let method: HTTP.Method
    let query: HTTP.Query?
    let body: Data?

    init(url: URL, headers: HTTP.Headers? = nil, method: HTTP.Method = .GET, query: HTTP.Query? = nil, body: Data? = nil) {
        self.url = url
        self.headers = headers
        self.method = method
        self.query = query
        self.body = body
    }
}
