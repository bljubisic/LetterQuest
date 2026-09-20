import XCTest

/// Flow 4 from issue #18: Settings → Reset All Progress removes every
/// `ChildProgress` record, verified via both the Home grid and Progress
/// screen after confirming the reset.
final class SettingsResetFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_resetAllProgress_clearsChildProgressRecords() throws {
        let app = XCUIApplication()
        app.launchEnvironment = LaunchArgumentBuilder()
            .resettingState()
            .skippingOnboarding()
            .seedingLetter("A", completed: true, score: 92)
            .seedingLetter("B", completed: true, score: 88)
            .build()
        app.launch()

        // Confirm seeded progress actually landed before resetting it.
        let progressButton = app.buttons["home.progressButton"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 5))
        progressButton.tap()
        let summaryBefore = app.otherElements["progress.summary"]
        XCTAssertTrue(summaryBefore.waitForExistence(timeout: 5))
        XCTAssertTrue(summaryBefore.label.contains("2 of 26"), summaryBefore.label)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Reset via Settings.
        let settingsButton = app.buttons["home.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        let resetButton = app.buttons["settings.resetButton"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5))
        resetButton.tap()

        let confirmButton = app.alerts.buttons["Reset"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Home should show only A unlocked again (B was reset to locked).
        // `LetterCard` uses `.accessibilityElement(children: .ignore)`, so the
        // identifier lands on a synthetic "other"-typed wrapper, not the
        // underlying `Button` — and SwiftUI doesn't propagate the button's
        // disabled trait onto that wrapper, so lock status has to be read
        // from `.value` (`accessibilityValue`) rather than `.isEnabled`.
        let letterA = app.otherElements["home.letterCard.A"]
        XCTAssertTrue(letterA.waitForExistence(timeout: 5))
        XCTAssertNotEqual(letterA.value as? String, "Locked")
        XCTAssertEqual(app.otherElements["home.letterCard.B"].value as? String, "Locked")

        progressButton.tap()
        let summaryAfter = app.otherElements["progress.summary"]
        XCTAssertTrue(summaryAfter.waitForExistence(timeout: 5))
        XCTAssertTrue(summaryAfter.label.contains("0 of 26"), summaryAfter.label)
    }
}
