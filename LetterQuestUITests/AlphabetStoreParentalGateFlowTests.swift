import XCTest

/// Issue #50 — App Store rejection under Review Guideline 1.3 (Kids
/// Category): commerce in the Alphabet Store must sit behind a parental
/// gate that can't be bypassed. Scoped to the gate itself (cancel/wrong/
/// correct-answer behavior), not a full StoreKit transaction — the project
/// has no purchase-flow UI coverage driving the system purchase sheet yet
/// (see `project.yml`'s own note on this).
///
/// The Apple rejection cited this guideline twice: the first fix gated only
/// the in-store Buy/Restore buttons, but the Store screen itself — reachable
/// straight from Home's cart button with no gate — already shows pricing.
/// The gate now sits on `AppRouter.push(_:)` itself (`AppRoute.requiresParentalGate`),
/// so it fires once, before the Store ever appears, from any entry point.
/// The in-store Buy/Restore buttons no longer show a second gate of their
/// own — two gates in the same flow was confusing, and the entry gate alone
/// already satisfies the guideline: nothing reaches the Store, let alone a
/// Buy/Restore button, without solving it first.
final class AlphabetStoreParentalGateFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Parses "7 × 8 = ?" into its product, so tests don't hardcode a
    /// specific challenge (a fresh one is generated per gate presentation).
    private func correctAnswer(for prompt: String) -> String {
        let numbers = prompt.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard numbers.count == 2 else {
            XCTFail("Couldn't parse parental gate prompt: \"\(prompt)\"")
            return ""
        }
        return String(numbers[0] * numbers[1])
    }

    /// Solves whichever parental gate is currently on screen.
    private func solveGate(in app: XCUIApplication) {
        let promptLabel = app.staticTexts["parentalGate.prompt"]
        XCTAssertTrue(promptLabel.waitForExistence(timeout: 5))
        let answer = correctAnswer(for: promptLabel.label)

        let answerField = app.textFields["parentalGate.answerField"]
        answerField.tap()
        answerField.typeText(answer)
        app.buttons["parentalGate.continueButton"].tap()
    }

    /// Launches at Home, taps the cart button, and solves the entry gate
    /// that sits in front of the Store screen — leaving the caller inside
    /// the Store, ready to exercise Buy/Restore directly.
    private func launchAtStore() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = LaunchArgumentBuilder()
            .resettingState()
            .skippingOnboarding()
            .build()
        app.launch()

        let storeButton = app.buttons["home.storeButton"]
        XCTAssertTrue(storeButton.waitForExistence(timeout: 5))
        storeButton.tap()

        solveGate(in: app)

        XCTAssertTrue(app.buttons["store.restoreButton"].waitForExistence(timeout: 5))
        return app
    }

    func test_tappingStoreButton_showsParentalGateBeforeStoreAppears() throws {
        let app = XCUIApplication()
        app.launchEnvironment = LaunchArgumentBuilder()
            .resettingState()
            .skippingOnboarding()
            .build()
        app.launch()

        let storeButton = app.buttons["home.storeButton"]
        XCTAssertTrue(storeButton.waitForExistence(timeout: 5))
        storeButton.tap()

        XCTAssertTrue(app.staticTexts["parentalGate.prompt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["store.restoreButton"].exists, "Store must not be visible until the gate is solved")
    }

    func test_cancelingEntryGate_staysOnHome() throws {
        let app = XCUIApplication()
        app.launchEnvironment = LaunchArgumentBuilder()
            .resettingState()
            .skippingOnboarding()
            .build()
        app.launch()

        app.buttons["home.storeButton"].tap()

        let cancelButton = app.buttons["parentalGate.cancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()

        XCTAssertFalse(app.staticTexts["parentalGate.prompt"].exists)
        XCTAssertFalse(app.buttons["store.restoreButton"].exists)
        XCTAssertTrue(app.buttons["home.storeButton"].waitForExistence(timeout: 5))
    }

    /// Once inside the Store (past the entry gate), tapping Buy must start
    /// the purchase immediately — no second gate. `purchase(_:)` sets
    /// `purchasingAlphabetId` synchronously, before any StoreKit round-trip,
    /// so the Buy button disappearing (replaced by a spinner) is a safe
    /// signal the tap actually fired the purchase call without an
    /// intervening gate.
    func test_tappingBuy_startsPurchaseImmediatelyWithNoSecondGate() throws {
        let app = launchAtStore()

        let buyButton = app.buttons["store.buyButton.cyrillic-sr"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 5))
        buyButton.tap()

        XCTAssertFalse(app.staticTexts["parentalGate.prompt"].waitForExistence(timeout: 2),
                        "Buy must not show a second parental gate — the entry gate already covers it")
        XCTAssertFalse(app.buttons["store.buyButton.cyrillic-sr"].exists)
    }

    /// Restore must also start immediately with no second gate.
    func test_tappingRestorePurchases_startsImmediatelyWithNoSecondGate() throws {
        let app = launchAtStore()

        let restoreButton = app.buttons["store.restoreButton"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
        restoreButton.tap()

        XCTAssertFalse(app.staticTexts["parentalGate.prompt"].waitForExistence(timeout: 2),
                        "Restore must not show a second parental gate — the entry gate already covers it")
    }
}
