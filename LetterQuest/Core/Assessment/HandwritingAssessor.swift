import Foundation
import PencilKit
import RxSwift

/// Contract for the handwriting scoring pipeline.
///
/// Conforming types receive a set of `PKStroke` objects plus the target `Letter`
/// and return a fully populated `AssessmentResult` wrapped in a `Single`.
/// The work may be done on any scheduler; callers observe on `MainScheduler`.
protocol HandwritingAssessing {
    /// Scores a drawing attempt against the letter template.
    ///
    /// - Parameters:
    ///   - strokes: All `PKStroke` objects currently on the canvas.
    ///   - letter: The target letter whose templates the drawing is compared against.
    ///   - guidelines: The proportion-checker guide-line positions for the canvas.
    /// - Returns: A `Single` that emits exactly one `AssessmentResult` then completes.
    func assess(
        strokes: [PKStroke],
        for letter: Letter,
        guidelines: ProportionChecker.Guidelines
    ) -> Single<AssessmentResult>
}

/// The production implementation of `HandwritingAssessing`.
///
/// Combines four independent scoring signals into one weighted composite:
///
/// | Signal            | Weight | Scorer                 |
/// |-------------------|--------|------------------------|
/// | Stroke order/path | 35 %   | `DTWMatcher`           |
/// | Shape accuracy    | 35 %   | `ShapeAnalyzer`        |
/// | Proportions       | 20 %   | `ProportionChecker`    |
/// | Smoothness        | 10 %   | `SmoothnessAnalyzer`   |
///
/// Scoring runs on `.userInitiated` quality-of-service so it never blocks the main thread.
final class HandwritingAssessor: HandwritingAssessing {

    private let dtwMatcher: DTWMatcher
    private let shapeAnalyzer: ShapeAnalyzer
    private let proportionChecker: ProportionChecker
    private let smoothnessAnalyzer: SmoothnessAnalyzer

    /// - Parameters:
    ///   - dtwMatcher: Compares stroke paths via Dynamic Time Warping.
    ///   - shapeAnalyzer: Compares the rendered bitmap against the reference via IoU.
    ///   - proportionChecker: Checks baseline, x-height, and width geometry.
    ///   - smoothnessAnalyzer: Measures angular jitter and speed variance.
    init(
        dtwMatcher: DTWMatcher         = DTWMatcher(),
        shapeAnalyzer: ShapeAnalyzer   = ShapeAnalyzer(),
        proportionChecker: ProportionChecker  = ProportionChecker(),
        smoothnessAnalyzer: SmoothnessAnalyzer = SmoothnessAnalyzer()
    ) {
        self.dtwMatcher         = dtwMatcher
        self.shapeAnalyzer      = shapeAnalyzer
        self.proportionChecker  = proportionChecker
        self.smoothnessAnalyzer = smoothnessAnalyzer
    }

    func assess(
        strokes: [PKStroke],
        for letter: Letter,
        guidelines: ProportionChecker.Guidelines
    ) -> Single<AssessmentResult> {
        Single.create { [weak self] observer in
            guard let self else { return Disposables.create() }

            DispatchQueue.global(qos: .userInitiated).async {
                let canvasSize = guidelines.canvasBounds.size

                // Recognition gate: find the best-matching character in the same group.
                // If the drawing looks more like a different character, reject early.
                let (recognized, confidence) = self.recognize(strokes: strokes, among: letter.letterCase, canvasSize: canvasSize)
                // Only reject when the drawn stroke count matches the target's expected count.
                // If counts differ, DTW already penalises the score; the gate would fire spuriously
                // (e.g. G drawn with 2 strokes matches Q's 2-template count, inflating Q's score).
                let strokeCountMatchesTarget = strokes.count == letter.strokeTemplates.count
                if strokeCountMatchesTarget && confidence > 65 && recognized != letter.character {
                    let result = AssessmentResult(
                        overallScore:     15,
                        strokeOrderScore: 0,
                        shapeScore:       0,
                        proportionScore:  0,
                        smoothnessScore:  0,
                        feedback:         [FeedbackItem(type: .shape,
                                                        message: "That looks like '\(recognized)'. Try drawing '\(letter.character)'!")],
                        passed:           false
                    )
                    observer(.success(result))
                    return
                }

                let strokeScore     = self.dtwMatcher.score(strokes: strokes, against: letter.strokeTemplates)
                let shapeScore      = self.shapeAnalyzer.score(strokes: strokes, for: letter, canvasSize: canvasSize)
                let proportionScore = self.proportionChecker.score(strokes: strokes, letter: letter, guidelines: guidelines)
                let smoothnessScore = self.smoothnessAnalyzer.score(strokes: strokes)

                let overall = Int(
                    Double(strokeScore)     * 0.35 +
                    Double(shapeScore)      * 0.35 +
                    Double(proportionScore) * 0.20 +
                    Double(smoothnessScore) * 0.10
                )

                let result = AssessmentResult(
                    overallScore:     overall,
                    strokeOrderScore: strokeScore,
                    shapeScore:       shapeScore,
                    proportionScore:  proportionScore,
                    smoothnessScore:  smoothnessScore,
                    feedback:         self.buildFeedback(
                        strokeScore:     strokeScore,
                        shapeScore:      shapeScore,
                        proportionScore: proportionScore,
                        smoothnessScore: smoothnessScore
                    ),
                    passed: overall >= 75
                )

                observer(.success(result))
            }

            return Disposables.create()
        }
    }

    // MARK: - Recognition

    /// Returns the best-matching character from `group` and its recognition score.
    /// Score ≤ 65 means the drawing is too ambiguous to classify confidently.
    private func recognize(strokes: [PKStroke], among group: LetterCase, canvasSize: CGSize) -> (character: Character, confidence: Int) {
        let candidates: [Letter]
        switch group {
        case .upper: candidates = Letter.alphabet
        case .lower: candidates = Letter.lowercaseAlphabet
        }

        var bestChar  = candidates.first!.character
        var bestScore = -1

        for candidate in candidates {
            let dtw   = dtwMatcher.score(strokes: strokes, against: candidate.strokeTemplates)
            let shape = shapeAnalyzer.score(strokes: strokes, for: candidate, canvasSize: canvasSize)
            let score = (dtw + shape) / 2
            if score > bestScore {
                bestScore = score
                bestChar  = candidate.character
            }
        }

        return (bestChar, bestScore)
    }

    // MARK: - Feedback builder

    /// Generates a prioritised list of feedback items based on which signals failed.
    ///
    /// At most one item is generated per signal. If all signals pass, a single
    /// encouragement item is returned instead.
    ///
    /// - Parameters:
    ///   - strokeScore: DTW score (0–100).
    ///   - shapeScore: IoU score (0–100).
    ///   - proportionScore: Geometry score (0–100).
    ///   - smoothnessScore: Jitter/speed score (0–100).
    /// - Returns: Ordered feedback items, most important first.
    private func buildFeedback(
        strokeScore: Int,
        shapeScore: Int,
        proportionScore: Int,
        smoothnessScore: Int
    ) -> [FeedbackItem] {
        var items: [FeedbackItem] = []

        if strokeScore < 60 {
            items.append(FeedbackItem(type: .strokeOrder, message: "Try drawing the strokes in the correct order!"))
        }
        if shapeScore < 60 {
            items.append(FeedbackItem(type: .shape, message: "Keep working on the shape — you're getting closer!"))
        }
        if proportionScore < 60 {
            items.append(FeedbackItem(type: .proportion, message: "Try to fit your letter between the guide lines."))
        }
        if smoothnessScore < 60 {
            items.append(FeedbackItem(type: .smoothness, message: "Slow down a little and draw smoothly."))
        }
        if items.isEmpty {
            items.append(FeedbackItem(type: .encouragement, message: "Amazing work! Keep it up!"))
        }

        return items
    }
}
