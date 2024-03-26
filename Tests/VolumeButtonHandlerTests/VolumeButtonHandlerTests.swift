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

    func testIncreaseVolume() throws {
        let volumeHandler = VolumeButtonHandler()
        volumeHandler.startHandler(disableSystemVolumeHandler: false)

        var volume = volumeHandler.currentVolume
        while volume < 0.1 {
            let originalVol = volumeHandler.currentVolume
            volumeHandler.increaseVolume(amount: 0.1)
            let modifiedVol = volumeHandler.currentVolume
            XCTAssertTrue(modifiedVol > originalVol)
        }
    }

    func testDecreaseVolume() throws {
        let volumeHandler = VolumeButtonHandler()
        volumeHandler.startHandler(disableSystemVolumeHandler: false)

        volumeHandler.setInitialVolume()
        var volume = volumeHandler.currentVolume

        while volume > 0.1 {
            let originalVol = volumeHandler.currentVolume
            print("VolumeButtonHandler testDecreaseVolume - originalVol: \(originalVol)")
            volumeHandler.decreaseVolume(amount: 0.1)
            volume = volumeHandler.currentVolume
            let modifiedVol = volumeHandler.currentVolume
            print("VolumeButtonHandler testDecreaseVolume - modifiedlVol: \(modifiedVol)")
            XCTAssertTrue(modifiedVol < originalVol)
        }
    }

    func testNilVolumeButtonHandler() throws {
        let volumeHandler = VolumeButtonHandler()
        volumeHandler.startHandler(disableSystemVolumeHandler: false)

        volumeHandler.stopHandler()
        XCTAssertEqual(volumeHandler.isStarted, false)
    }
}
