import XCTest
@testable import VolumeButtonHandler

final class VolumeButtonHandlerTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        
        let volumeButtonHandler = VolumeButtonHandler()
        volumeButtonHandler.startHandler(disableSystemVolumeHandler: false)
        
        XCTAssertNotNil(volumeButtonHandler)
    }
}
