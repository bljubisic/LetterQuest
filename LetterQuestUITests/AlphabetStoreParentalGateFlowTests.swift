import XCTest

/// Issue #50 — App Store rejection under Review Guideline 1.3 (Kids
/// Category): commerce in the Alphabet Store must sit behind a parental
/// gate that can't be bypassed. Scoped to the gate itself (cancel/wrong/
/// correct-answer behavior), not a full StoreKit transaction — the project
/// has no purchase-flow UI coverage driving the system purchase sheet yet
/// (see `project.yml`'s own note on this).
final class AlphabetStoreParentalGateFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

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
        return app
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

    func test_tappingBuy_showsParentalGate() throws {
        let app = launchAtStore()

        let buyButton = app.buttons["store.buyButton.cyrillic-sr"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 5))
        buyButton.tap()

        XCTAssertTrue(app.staticTexts["parentalGate.prompt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["parentalGate.answerField"].exists)
    }

    func test_cancelingGate_leavesAlphabetUnpurchased() throws {
        let app = launchAtStore()

        app.buttons["store.buyButton.cyrillic-sr"].tap()

        let cancelButton = app.buttons["parentalGate.cancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()

        XCTAssertFalse(app.staticTexts["parentalGate.prompt"].exists)
        XCTAssertTrue(app.buttons["store.buyButton.cyrillic-sr"].waitForExistence(timeout: 5))
    }

    func test_wrongAnswer_keepsGateUpAndDoesNotPurchase() throws {
        let app = launchAtStore()

        app.buttons["store.buyButton.cyrillic-sr"].tap()

        let answerField = app.textFields["parentalGate.answerField"]
        XCTAssertTrue(answerField.waitForExistence(timeout: 5))
        answerField.tap()
        answerField.typeText("1")
        app.buttons["parentalGate.continueButton"].tap()

        XCTAssertTrue(app.staticTexts["parentalGate.errorMessage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["parentalGate.answerField"].exists, "Gate should still be showing")
    }

    func test_correctAnswer_dismissesGateAndStartsPurchase() throws {
        let app = launchAtStore()

        app.buttons["store.buyButton.cyrillic-sr"].tap()

        let promptLabel = app.staticTexts["parentalGate.prompt"]
        XCTAssertTrue(promptLabel.waitForExistence(timeout: 5))
        let answer = correctAnswer(for: promptLabel.label)

        let answerField = app.textFields["parentalGate.answerField"]
        answerField.tap()
        answerField.typeText(answer)
        app.buttons["parentalGate.continueButton"].tap()

        // The gate dismisses and `AlphabetStoreViewModel.purchase(_:)` sets
        // `purchasingAlphabetId` synchronously, before any StoreKit
        // round-trip — so the Buy button disappearing (replaced by a
        // spinner) is a safe signal the gate actually unblocked the
        // purchase call, without needing to drive the system purchase sheet.
        XCTAssertFalse(app.staticTexts["parentalGate.prompt"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["store.buyButton.cyrillic-sr"].exists)
    }

    func test_tappingRestorePurchases_showsParentalGate() throws {
        let app = launchAtStore()

        let restoreButton = app.buttons["store.restoreButton"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
        restoreButton.tap()

        XCTAssertTrue(app.staticTexts["parentalGate.prompt"].waitForExistence(timeout: 5))
    }
}
