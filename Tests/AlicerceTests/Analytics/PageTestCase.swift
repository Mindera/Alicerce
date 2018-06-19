import XCTest

@testable import Alicerce

final class PageTestCase: XCTestCase {
    
    func testPage_WithOnlyNameProvided_ItShouldPopulateOnlyTheName() {
        let page = Analytics.Page(name: "🤠", parameters: nil)
        
        XCTAssertEqual(page.name, "🤠")
        XCTAssertNil(page.parameters)
    }
    
    func testPage_WithProvidedNameAndParameters_ItShouldPopulateOnlyTheName() {
        let page = Analytics.Page(name: "🔨", parameters: ["1" : "1"])
        
        XCTAssertEqual(page.name, "🔨")
        XCTAssertNotNil(page.parameters)
        XCTAssertEqual(page.parameters?.count, 1)
    }
    
    func testPages_WithDifferentValuesProvided_ShouldBeDifferent(){
        let lhs = Analytics.Page(name: "🔨", parameters: ["1" : "1"])
        let rhs = Analytics.Page(name: "🤠", parameters: ["1" : "2"])
        
        XCTAssertNotEqual(lhs,rhs)
    }
    
    func testPages_WithSameValuesProvided_ShouldBeEqual(){
        let lhs = Analytics.Page(name: "🔨", parameters: ["1" : "1"])
        let rhs = Analytics.Page(name: "🔨", parameters: ["1" : "1"])
        
        XCTAssertEqual(lhs,rhs)
    }
}
