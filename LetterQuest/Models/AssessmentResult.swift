import Foundation

/// A child-friendly message produced by one scoring signal.
struct FeedbackItem: FeedbackItemProtocol, Equatable {
    let type: FeedbackType
    let message: String
}

/// The immutable result of assessing a single drawing attempt.
///
/// Scores are in **0–100**. The composite `overallScore` is:
/// - Stroke order/direction: 35 %  (DTWMatcher)
/// - Shape accuracy:         35 %  (ShapeAnalyzer)
/// - Proportions:            20 %  (ProportionChecker)
/// - Smoothness:             10 %  (SmoothnessAnalyzer)
///
/// `passed` is `true` when `overallScore >= 75`.
///
/// All properties are read-only. Use `AssessmentResult`'s lenses to derive
/// modified copies for testing or calibration purposes.
struct AssessmentResult: AssessmentResultProtocol, Equatable {

    let overallScore: Int
    let strokeOrderScore: Int
    let shapeScore: Int
    let proportionScore: Int
    let smoothnessScore: Int
    let feedback: [FeedbackItem]
    let passed: Bool
}

// MARK: - Lenses

extension AssessmentResult {

    /// Focuses on `feedback`. Useful in tests to inject custom feedback items.
    static let lensFeedback = Lens<AssessmentResult, [FeedbackItem]>(
        get: { $0.feedback },
        set: { whole, value in
            AssessmentResult(
                overallScore:    whole.overallScore,
                strokeOrderScore: whole.strokeOrderScore,
                shapeScore:      whole.shapeScore,
                proportionScore: whole.proportionScore,
                smoothnessScore: whole.smoothnessScore,
                feedback:        value,
                passed:          whole.passed
            )
        }
    )

    /// Focuses on `passed`. Useful to override the pass/fail threshold in tests.
    static let lensPassed = Lens<AssessmentResult, Bool>(
        get: { $0.passed },
        set: { whole, value in
            AssessmentResult(
                overallScore:    whole.overallScore,
                strokeOrderScore: whole.strokeOrderScore,
                shapeScore:      whole.shapeScore,
                proportionScore: whole.proportionScore,
                smoothnessScore: whole.smoothnessScore,
                feedback:        whole.feedback,
                passed:          value
            )
        }
    )
}
