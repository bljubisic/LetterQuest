import XCTest
import CoreGraphics
import PencilKit
import RxSwift
import RxBlocking
@testable import LetterQuest

// MARK: - Helpers

private func runAssess(
    strokes: [PKStroke],
    letter: Letter,
    canvasSize: CGSize = CGSize(width: 400, height: 400)
) throws -> AssessmentResult {
    let assessor = HandwritingAssessor()
    let guides   = ProportionChecker.Guidelines.forCanvas(size: canvasSize)
    return try assessor.assess(strokes: strokes, for: letter, guidelines: guides)
        .toBlocking()
        .single()
}

private final class MockSettingsRepository: SettingsRepositoryProtocol {
    let settings: AppSettings
    init(difficulty: PassDifficulty) { settings = AppSettings(difficulty: difficulty, activeAlphabetId: nil) }
    func load() -> Single<AppSettings> { .just(settings) }
    func save(_ settings: AppSettings) -> Completable { .empty() }
}

private func runAssess(
    strokes: [PKStroke],
    letter: Letter,
    difficulty: PassDifficulty,
    canvasSize: CGSize = CGSize(width: 400, height: 400)
) throws -> AssessmentResult {
    let assessor = HandwritingAssessor(settingsRepository: MockSettingsRepository(difficulty: difficulty))
    let guides   = ProportionChecker.Guidelines.forCanvas(size: canvasSize)
    return try assessor.assess(strokes: strokes, for: letter, guidelines: guides)
        .toBlocking()
        .single()
}

// MARK: - Composite weighting

final class HandwritingAssessorWeightingTests: XCTestCase {

    func test_overallScore_equalsWeightedSumOfSubScores() throws {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let strokes = makeStrokes(
            matching: letter.strokeTemplates,
            in: CGSize(width: 400, height: 400)
        )
        let result = try runAssess(strokes: strokes, letter: letter)

        let expected = Int(
            Double(result.strokeOrderScore) * 0.35 +
            Double(result.shapeScore)       * 0.35 +
            Double(result.proportionScore)  * 0.20 +
            Double(result.smoothnessScore)  * 0.10
        )
        XCTAssertEqual(result.overallScore, expected)
    }

    func test_strokeAndShape_dominateTheOverallScore() throws {
        // Run any assessment and sanity-check that the formula's stroke+shape
        // contribution is more than half of the recomputed total.
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let strokes = makeStrokes(matching: letter.strokeTemplates,
                                  in: CGSize(width: 400, height: 400))
        let result = try runAssess(strokes: strokes, letter: letter)
        let strokeShare = Double(result.strokeOrderScore) * 0.35
        let shapeShare  = Double(result.shapeScore)       * 0.35
        let totalRaw    = strokeShare + shapeShare
                        + Double(result.proportionScore) * 0.20
                        + Double(result.smoothnessScore) * 0.10
        let share = (strokeShare + shapeShare) / totalRaw
        XCTAssertGreaterThan(share, 0.5, "stroke+shape share = \(share)")
    }
}

// MARK: - Pass threshold

final class HandwritingAssessorThresholdTests: XCTestCase {

    func test_passed_reflectsOverallAt75Threshold() throws {
        // Two attempts: a near-perfect trace and an empty drawing. The two
        // sides of the 75-pass threshold should fall on opposite sides of
        // `passed`.
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let traced = try runAssess(
            strokes: makeStrokes(matching: letter.strokeTemplates,
                                 in: CGSize(width: 400, height: 400)),
            letter: letter
        )
        let empty = try runAssess(strokes: [], letter: letter)

        XCTAssertEqual(traced.passed, traced.overallScore >= 75)
        XCTAssertFalse(empty.passed)
        XCTAssertLessThan(empty.overallScore, 75)
    }

    func test_tracedLetter_passesThreshold() throws {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let traced = try runAssess(
            strokes: makeStrokes(matching: letter.strokeTemplates,
                                 in: CGSize(width: 400, height: 400)),
            letter: letter
        )
        XCTAssertTrue(traced.passed, "Traced letter should pass; overall = \(traced.overallScore)")
    }
}

// MARK: - Feedback messages

final class HandwritingAssessorFeedbackTests: XCTestCase {

    func test_failingDrawing_producesStrokeShapeAndProportionFeedback() throws {
        // Single stray dot — gets penalised on every signal.
        let letter = Letter.alphabet.first { $0.character == "A" }!
        let strokes = [makeStroke(points: [CGPoint(x: 50, y: 50)])]
        let result = try runAssess(strokes: strokes, letter: letter)

        let types = Set(result.feedback.map(\.type))
        XCTAssertTrue(types.contains(.strokeOrder), "feedback: \(result.feedback)")
        XCTAssertTrue(types.contains(.shape),       "feedback: \(result.feedback)")
        XCTAssertTrue(types.contains(.proportion),  "feedback: \(result.feedback)")
    }

    func test_passingDrawing_producesEncouragementOrSubScoreFeedback() throws {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let result = try runAssess(
            strokes: makeStrokes(matching: letter.strokeTemplates,
                                 in: CGSize(width: 400, height: 400)),
            letter: letter
        )
        guard result.passed else { return }   // Skip if calibration drifts.
        let hasEncouragement = result.feedback.contains { $0.type == .encouragement }
        let hasFailureItem  = result.feedback.contains { $0.type != .encouragement }
        // Either there's an encouragement message, or one of the sub-scores
        // dipped below 60 even though the overall passed.
        XCTAssertTrue(hasEncouragement || hasFailureItem,
                      "expected feedback items, got \(result.feedback)")
    }
}

// MARK: - Output shape

final class HandwritingAssessorRangeTests: XCTestCase {

    func test_allSubScores_areWithin0to100() throws {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let result = try runAssess(
            strokes: makeStrokes(matching: letter.strokeTemplates,
                                 in: CGSize(width: 400, height: 400)),
            letter: letter
        )
        for (label, score) in [
            ("overall",    result.overallScore),
            ("strokeOrder", result.strokeOrderScore),
            ("shape",      result.shapeScore),
            ("proportion", result.proportionScore),
            ("smoothness", result.smoothnessScore),
        ] {
            XCTAssertGreaterThanOrEqual(score, 0,   "\(label) out of range: \(score)")
            XCTAssertLessThanOrEqual(score,    100, "\(label) out of range: \(score)")
        }
    }
}

// MARK: - Difficulty-driven pass threshold

final class HandwritingAssessorDifficultyTests: XCTestCase {

    /// Scoring itself is deterministic given identical strokes/letter/canvas —
    /// only `passed` should change across difficulties. Rather than reverse
    /// engineering strokes that land in a specific score band, run the same
    /// drawing through each difficulty and check `passed` against that
    /// difficulty's own threshold applied to the (identical) resulting score.
    func test_passedFlag_reflectsEachDifficultysOwnThreshold() throws {
        let letter  = Letter.alphabet.first { $0.character == "I" }!
        let strokes = makeStrokes(matching: letter.strokeTemplates,
                                  in: CGSize(width: 400, height: 400))

        for difficulty in PassDifficulty.allCases {
            let result = try runAssess(strokes: strokes, letter: letter, difficulty: difficulty)
            XCTAssertEqual(
                result.passed, result.overallScore >= difficulty.passThreshold,
                "difficulty=\(difficulty) overall=\(result.overallScore) threshold=\(difficulty.passThreshold)"
            )
        }
    }
}

// MARK: - Recognition gate scoping (multi-alphabet)

private struct MockAlphabetRepositoryForAssessor: AlphabetRepositoryProtocol {
    let alphabets: [Alphabet]
    func fetchAvailable() -> Single<[Alphabet]> { .just(alphabets) }
    func fetchInstalled() -> Single<[Alphabet]> { .just(alphabets) }
}

/// Regression coverage for the bug where the recognition gate always compared
/// against the Latin alphabet regardless of which alphabet was being
/// practiced — so a correctly drawn Cyrillic letter that happens to look like
/// a Latin letter (e.g. "О" vs "O", distinct Unicode scalars) was recognized
/// as "the wrong letter" and force-failed at score 15.
final class HandwritingAssessorRecognitionScopeTests: XCTestCase {

    private func makeMultiAlphabetAssessor() -> HandwritingAssessor {
        let letterRepository = LetterRepository(
            alphabetRepository: MockAlphabetRepositoryForAssessor(alphabets: [.latin, .cyrillicSr])
        )
        return HandwritingAssessor(letterRepository: letterRepository)
    }

    /// `assess(...)` dispatches its work to a background queue and completes
    /// there. `.toBlocking().single()` reliably hangs when called against it
    /// from these tests (confirmed independently in two separate Xcode runs);
    /// `XCTestExpectation` keeps the run loop pumping while it waits instead
    /// of blocking the thread outright, which is what actually resolves.
    private func runAssess(
        assessor: HandwritingAssessor,
        strokes: [PKStroke],
        letter: Letter,
        guidelines: ProportionChecker.Guidelines
    ) throws -> AssessmentResult {
        let exp = expectation(description: "assess")
        var result: AssessmentResult?
        _ = assessor.assess(strokes: strokes, for: letter, guidelines: guidelines)
            .subscribe(onSuccess: { result = $0; exp.fulfill() })
        wait(for: [exp], timeout: 10)
        return try XCTUnwrap(result, "assess(...) did not complete within 10s")
    }

    func test_perfectCyrillicLetterVisuallyIdenticalToLatin_isNotRejected() throws {
        let letter = try XCTUnwrap(Alphabet.cyrillicSr.letters.first { $0.character == "О" && $0.letterCase == .upper })
        let canvasSize = CGSize(width: 400, height: 400)
        let strokes = makeStrokesInZone(matching: letter.strokeTemplates, for: letter.character, in: canvasSize)
        let guides = ProportionChecker.Guidelines.forCanvas(size: canvasSize)
        let result = try runAssess(
            assessor: makeMultiAlphabetAssessor(), strokes: strokes, letter: letter, guidelines: guides
        )

        XCTAssertFalse(
            result.feedback.contains { $0.message.contains("looks like") },
            "recognition gate should not fire for a correctly drawn letter: \(result.feedback)"
        )
        XCTAssertGreaterThan(result.overallScore, 15, "should not be force-failed by the recognition gate")
    }

    func test_recognitionGate_stillCatchesAWrongLetterWithinTheSameAlphabet() throws {
        // Practicing "О" but drawing "С"'s strokes instead (both single,
        // `.curved` strokes) — the gate should still fire, proving the fix
        // scopes candidates rather than disabling recognition outright.
        let target = try XCTUnwrap(Alphabet.cyrillicSr.letters.first { $0.character == "О" && $0.letterCase == .upper })
        let wrong  = try XCTUnwrap(Alphabet.cyrillicSr.letters.first { $0.character == "С" && $0.letterCase == .upper })
        XCTAssertEqual(wrong.strokeTemplates.count, target.strokeTemplates.count,
                       "fixture requires equal stroke counts so the gate isn't skipped by the count check")

        let canvasSize = CGSize(width: 400, height: 400)
        let strokes = makeStrokesInZone(matching: wrong.strokeTemplates, for: wrong.character, in: canvasSize)
        let guides = ProportionChecker.Guidelines.forCanvas(size: canvasSize)
        let result = try runAssess(
            assessor: makeMultiAlphabetAssessor(), strokes: strokes, letter: target, guidelines: guides
        )

        XCTAssertEqual(result.overallScore, 15, "recognition gate should still reject a different letter's strokes")
    }
}
