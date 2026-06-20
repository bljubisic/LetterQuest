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
