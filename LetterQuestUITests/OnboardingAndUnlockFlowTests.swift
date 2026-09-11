import XCTest

/// Flow 1 from issue #18: first launch → complete letter A → letter B
/// unlocks. Verifies onboarding, the practice submission pipeline, and the
/// unlock-next-letter logic end-to-end.
final class OnboardingAndUnlockFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_firstLaunch_completeA_unlocksB() throws {
        let app = XCUIApplication()
        app.launchEnvironment = LaunchArgumentBuilder()
            .resettingState()
            .autoPassing()
            .build()
        app.launch()

        let skipButton = app.buttons["onboarding.skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        skipButton.tap()

        // Only A starts unlocked. `LetterCard` uses
        // `.accessibilityElement(children: .ignore)`, so the identifier lands
        // on a synthetic "other"-typed wrapper, not the underlying `Button` —
        // and SwiftUI doesn't propagate the button's disabled trait onto that
        // wrapper, so lock status has to be read from `.value`
        // (`accessibilityValue`) rather than `.isEnabled`.
        let letterA = app.otherElements["home.letterCard.A"]
        XCTAssertTrue(letterA.waitForExistence(timeout: 5))
        XCTAssertNotEqual(letterA.value as? String, "Locked")
        XCTAssertEqual(app.otherElements["home.letterCard.B"].value as? String, "Locked")

        app.navigateToPractice(for: "A")
        app.drawAndSubmit()

        let celebrationButton = app.buttons["celebration.continueButton"]
        XCTAssertTrue(celebrationButton.waitForExistence(timeout: 5), "Celebration should appear after a passing submission")
        celebrationButton.tap()

        // continueToNext() replaces the nav stack with letter B's practice
        // screen directly (the real unlock pipeline ran via the injected
        // result) — confirm we landed there, then pop back to Home to verify
        // the grid reflects the unlock.
        XCTAssertTrue(app.staticTexts["Draw the letter B"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let letterB = app.otherElements["home.letterCard.B"]
        XCTAssertTrue(letterB.waitForExistence(timeout: 5))
        XCTAssertNotEqual(letterB.value as? String, "Locked")
        XCTAssertEqual(app.otherElements["home.letterCard.C"].value as? String, "Locked")
    }
}
