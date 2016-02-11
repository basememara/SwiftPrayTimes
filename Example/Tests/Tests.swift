import UIKit
import XCTest
import SwiftPrayTimes

class Tests: XCTestCase {
    
    var prayTimes: PrayTimes!
    
    override func setUp() {
        super.setUp()
        
        prayTimes = PrayTimes()
    }
    
    func testGetTimeName() {
        let value = PrayTimes.TimeName.Fajr
        let expectedValue = "Fajr"
        
        XCTAssertEqual(value.getName(), expectedValue,
            "String should be \(expectedValue)")
    }
    
}
