import Foundation
import PencilKit
import RxSwift
import os

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
    private let settingsRepository: SettingsRepositoryProtocol

    /// Marks the assessment pipeline for Instruments. The log handle's
    /// category must be the reserved `.pointsOfInterest` value — that's what
    /// Instruments' "Points of Interest" instrument filters on (subsystem can
    /// be anything); a custom category like "Assessment" is invisible to that
    /// specific instrument even though it'd show fine in the more general
    /// "os_signpost" instrument. See issue #17.
    private let signposter = OSSignposter(
        logHandle: OSLog(subsystem: "com.letterquest.app", category: .pointsOfInterest)
    )

    /// - Parameters:
    ///   - dtwMatcher: Compares stroke paths via Dynamic Time Warping.
    ///   - shapeAnalyzer: Compares the rendered bitmap against the reference via IoU.
    ///   - proportionChecker: Checks baseline, x-height, and width geometry.
    ///   - smoothnessAnalyzer: Measures angular jitter and speed variance.
    ///   - settingsRepository: Source of the current pass-threshold difficulty.
    init(
        dtwMatcher: DTWMatcher         = DTWMatcher(),
        shapeAnalyzer: ShapeAnalyzer   = ShapeAnalyzer(),
        proportionChecker: ProportionChecker  = ProportionChecker(),
        smoothnessAnalyzer: SmoothnessAnalyzer = SmoothnessAnalyzer(),
        settingsRepository: SettingsRepositoryProtocol = SettingsRepository()
    ) {
        self.dtwMatcher         = dtwMatcher
        self.shapeAnalyzer      = shapeAnalyzer
        self.proportionChecker  = proportionChecker
        self.smoothnessAnalyzer = smoothnessAnalyzer
        self.settingsRepository = settingsRepository
    }

    func assess(
        strokes: [PKStroke],
        for letter: Letter,
        guidelines: ProportionChecker.Guidelines
    ) -> Single<AssessmentResult> {
        Single.create { [weak self] observer in
            guard let self else { return Disposables.create() }

            DispatchQueue.global(qos: .userInitiated).async {
                let signpostID = self.signposter.makeSignpostID()
                let assessInterval = self.signposter.beginInterval("Assess", id: signpostID)
                defer { self.signposter.endInterval("Assess", assessInterval) }

                let canvasSize = guidelines.canvasBounds.size

                // `settingsRepository.load()` is `UserDefaults`-backed and always
                // completes synchronously (no real async gap), so a plain
                // subscribe-then-dispose captures the value immediately without
                // pulling in RxBlocking (test-only; not linked into this target).
                var settings = AppSettings.default
                self.settingsRepository.load()
                    .subscribe(onSuccess: { settings = $0 }, onFailure: { _ in })
                    .dispose()
                let passThreshold = settings.difficulty.passThreshold

                // Recognition gate: find the best-matching character in the same group.
                // If the drawing looks more like a different character, reject early.
                //
                // This scores the drawing against every candidate letter in the
                // same case (~26x the DTW+shape cost of a normal submission) —
                // instrumented on its own so Instruments can show how much of a
                // submission's total time this gate accounts for (see issue #17).
                let (recognized, confidence) = self.signposter.withIntervalSignpost("RecognitionGate", id: signpostID) {
                    self.recognize(strokes: strokes, among: letter.letterCase, canvasSize: canvasSize)
                }
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

                let strokeScore = self.signposter.withIntervalSignpost("DTWScore", id: signpostID) {
                    self.dtwMatcher.score(strokes: strokes, against: letter.strokeTemplates)
                }
                let shapeScore = self.signposter.withIntervalSignpost("ShapeScore", id: signpostID) {
                    self.shapeAnalyzer.score(strokes: strokes, for: letter, canvasSize: canvasSize)
                }
                let proportionScore = self.signposter.withIntervalSignpost("ProportionScore", id: signpostID) {
                    self.proportionChecker.score(strokes: strokes, letter: letter, guidelines: guidelines)
                }
                let smoothnessScore = self.signposter.withIntervalSignpost("SmoothnessScore", id: signpostID) {
                    self.smoothnessAnalyzer.score(strokes: strokes)
                }

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
                    passed: overall >= passThreshold
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

        // Renders the drawn strokes' bitmaps once and reuses them across all
        // candidates, instead of once per candidate (see `ShapeAnalyzer.scores`).
        let shapeScores = shapeAnalyzer.scores(strokes: strokes, against: candidates, canvasSize: canvasSize)

        var bestChar  = candidates.first!.character
        var bestScore = -1

        for (candidate, shape) in zip(candidates, shapeScores) {
            let dtw   = dtwMatcher.score(strokes: strokes, against: candidate.strokeTemplates)
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
