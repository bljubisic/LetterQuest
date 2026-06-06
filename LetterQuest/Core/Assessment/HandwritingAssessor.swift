import Foundation
import PencilKit
import RxSwift

protocol HandwritingAssessing {
    func assess(
        strokes: [PKStroke],
        for letter: Letter,
        guidelines: ProportionChecker.Guidelines
    ) -> Single<AssessmentResult>
}

final class HandwritingAssessor: HandwritingAssessing {

    private let dtwMatcher: DTWMatcher
    private let shapeAnalyzer: ShapeAnalyzer
    private let proportionChecker: ProportionChecker
    private let smoothnessAnalyzer: SmoothnessAnalyzer

    init(
        dtwMatcher: DTWMatcher = DTWMatcher(),
        shapeAnalyzer: ShapeAnalyzer = ShapeAnalyzer(),
        proportionChecker: ProportionChecker = ProportionChecker(),
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
                let strokeScore     = self.dtwMatcher.score(strokes: strokes, against: letter.strokeTemplates)
                let shapeScore      = letter.templateImage
                    .map { self.shapeAnalyzer.score(strokes: strokes, templateImage: $0) } ?? 50
                let proportionScore = self.proportionChecker.score(strokes: strokes, letter: letter, guidelines: guidelines)
                let smoothnessScore = self.smoothnessAnalyzer.score(strokes: strokes)

                let overall = Int(
                    Double(strokeScore)     * 0.35 +
                    Double(shapeScore)      * 0.35 +
                    Double(proportionScore) * 0.20 +
                    Double(smoothnessScore) * 0.10
                )

                let result = AssessmentResult(
                    overallScore: overall,
                    strokeOrderScore: strokeScore,
                    shapeScore: shapeScore,
                    proportionScore: proportionScore,
                    smoothnessScore: smoothnessScore,
                    feedback: self.buildFeedback(
                        strokeScore: strokeScore,
                        shapeScore: shapeScore,
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

    private func buildFeedback(
        strokeScore: Int,
        shapeScore: Int,
        proportionScore: Int,
        smoothnessScore: Int
    ) -> [AssessmentResult.FeedbackItem] {
        var items: [AssessmentResult.FeedbackItem] = []

        if strokeScore < 60 {
            items.append(.init(type: .strokeOrder, message: "Try drawing the strokes in the correct order!"))
        }
        if shapeScore < 60 {
            items.append(.init(type: .shape, message: "Keep working on the shape — you're getting closer!"))
        }
        if proportionScore < 60 {
            items.append(.init(type: .proportion, message: "Try to fit your letter between the guide lines."))
        }
        if smoothnessScore < 60 {
            items.append(.init(type: .smoothness, message: "Slow down a little and draw smoothly."))
        }
        if items.isEmpty {
            items.append(.init(type: .encouragement, message: "Amazing work! Keep it up!"))
        }

        return items
    }
}
