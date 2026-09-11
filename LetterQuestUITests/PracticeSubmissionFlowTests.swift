import XCTest

/// Flow 2 from issue #18: clear canvas → redraw → submit → pass →
/// celebration shown. Verifies the full practice loop's UI logic (Check!
/// disabled with no strokes, Clear resets it) alongside a real submission.
final class PracticeSubmissionFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_clearRedrawSubmit_pass_showsCelebration() throws {
        let app = XCUIApplication()
        app.launchEnvironment = LaunchArgumentBuilder()
            .resettingState()
            .skippingOnboarding()
            .autoPassing()
            .build()
        app.launch()

        app.navigateToPractice(for: "A")

        let canvas = app.otherElements["practice.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        let checkButton = app.buttons["practice.checkButton"]
        XCTAssertFalse(checkButton.isEnabled, "Check! should start disabled with an empty canvas")

        // Draw, then clear — Check! should re-disable.
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let end   = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertTrue(checkButton.isEnabled, "Check! should enable once a stroke exists")

        let clearButton = app.buttons["practice.clearButton"]
        clearButton.tap()
        XCTAssertFalse(checkButton.isEnabled, "Check! should disable again after Clear")

        // Redraw, then submit for real.
        app.drawAndSubmit()

        let celebration = app.buttons["celebration.continueButton"]
        XCTAssertTrue(celebration.waitForExistence(timeout: 5), "Celebration should appear after a passing submission")
    }
}
