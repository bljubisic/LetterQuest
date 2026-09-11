import XCTest

/// Shared navigation/interaction helpers used by more than one flow test, so
/// each test file reads as its own user journey instead of repeating the
/// low-level element lookups.
extension XCUIApplication {

    /// Taps the Home letter card for `character`, then "Let's practice!" on
    /// the Learn screen that follows, landing on the Practice screen.
    func navigateToPractice(for character: Character, timeout: TimeInterval = 5) {
        // `LetterCard` uses `.accessibilityElement(children: .ignore)`, which
        // moves the identifier onto a synthetic "other"-typed wrapper — the
        // underlying `Button` itself carries no identifier.
        let card = otherElements["home.letterCard.\(character)"]
        XCTAssertTrue(card.waitForExistence(timeout: timeout), "Letter card \(character) not found")
        card.tap()

        let practiceButton = buttons["learn.practiceButton"]
        XCTAssertTrue(practiceButton.waitForExistence(timeout: timeout), "\"Let's practice!\" button not found")
        practiceButton.tap()
    }

    /// Draws an arbitrary diagonal stroke on the practice canvas and taps
    /// "Check!". Real scoring accuracy isn't exercised by this stroke — pair
    /// with `LaunchArgumentBuilder.autoPassing()` so the submission passes
    /// deterministically via `E2ETestSupport`'s injected result.
    func drawAndSubmit(timeout: TimeInterval = 5) {
        let canvas = otherElements["practice.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: timeout), "Practice canvas not found")

        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let end   = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        start.press(forDuration: 0.05, thenDragTo: end)

        let checkButton = buttons["practice.checkButton"]
        XCTAssertTrue(checkButton.waitForExistence(timeout: timeout))
        XCTAssertTrue(checkButton.isEnabled, "Check! should be enabled once a stroke exists")
        checkButton.tap()
    }
}
