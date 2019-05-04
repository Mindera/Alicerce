import XCTest
@testable import Alicerce

class URLRequestTestCase: XCTestCase {
    
    func testURLRequest_ShouldCreateNSURLRequest() {
        let request = URLRequest(url: URL(string: "www.mindera.com")!)

        let nsURLRequest = request.nsURLRequest
        let request2 = nsURLRequest as URLRequest

        XCTAssertEqual(request, request2)
    }
}
