import XCTest
@testable import StompClientKit

final class StompClientKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(StompClientKit().version, "1.0.0")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
