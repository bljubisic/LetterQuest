import XCTest

/// Flow 3 from issue #18: the Progress screen shows all 26 letters with the
/// correct completion status after seeding progress data.
final class ProgressScreenTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_progressScreen_showsAll26LettersWithSeededStatus() throws {
        let app = XCUIApplication()
        app.launchEnvironment = LaunchArgumentBuilder()
            .resettingState()
            .skippingOnboarding()
            .seedingLetter("A", completed: true, score: 92)
            .seedingLetter("B", completed: true, score: 78)
            .seedingLetter("C", completed: false, score: 45)
            .build()
        app.launch()

        let progressButton = app.buttons["home.progressButton"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 5))
        progressButton.tap()

        // Summary reflects exactly the two completed letters.
        let summary = app.otherElements["progress.summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.contains("2 of 26"), "expected '2 of 26', got: \(summary.label)")

        // Spot-check individual rows via the combined accessibility label
        // built in issue #15's accessibility work.
        let rowA = app.otherElements["progress.letterRow.A"]
        XCTAssertTrue(rowA.waitForExistence(timeout: 5))
        XCTAssertTrue(rowA.label.contains("Completed"), rowA.label)
        XCTAssertTrue(rowA.label.contains("92 percent"), rowA.label)

        let rowC = app.otherElements["progress.letterRow.C"]
        XCTAssertTrue(rowC.label.contains("In progress"), rowC.label)

        let rowD = app.otherElements["progress.letterRow.D"]
        XCTAssertTrue(rowD.label.contains("Locked"), rowD.label)

        // All 26 uppercase letters should be present, seeded or not. `List`
        // is lazily backed — off-screen rows don't exist in the accessibility
        // tree until scrolled into view, so collect visible rows and scroll
        // until no new ones appear.
        var seenCharacters = Set<Character>()
        var previousCount = -1
        var swipes = 0
        while seenCharacters.count != previousCount && seenCharacters.count < 26 && swipes < 15 {
            previousCount = seenCharacters.count
            for character in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" where !seenCharacters.contains(character) {
                if app.otherElements["progress.letterRow.\(character)"].exists {
                    seenCharacters.insert(character)
                }
            }
            if seenCharacters.count < 26 {
                app.swipeUp()
                swipes += 1
            }
        }
        XCTAssertEqual(seenCharacters.count, 26, "expected all 26 letter rows, saw: \(seenCharacters.sorted())")
    }
}
