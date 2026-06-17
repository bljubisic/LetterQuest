import Testing
import PencilKit
import CoreGraphics
@testable import LetterQuest

// MARK: - Helpers

private func makeStroke(points: [CGPoint]) -> PKStroke {
    let strokePoints = points.enumerated().map { i, pt in
        PKStrokePoint(
            location: pt,
            timeOffset: TimeInterval(i) * 0.01,
            size: CGSize(width: 5, height: 5),
            opacity: 1,
            force: 1,
            azimuth: 0,
            altitude: .pi / 2
        )
    }
    let path = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
    return PKStroke(ink: PKInk(.pen), path: path)
}

private func makeTemplate(
    _ points: [CGPoint],
    index: Int = 0,
    direction: StrokeDirection = .topToBottom
) -> StrokeTemplate {
    StrokeTemplate(id: UUID(), strokeIndex: index, points: points, direction: direction)
}

private let verticalPoints: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
    .map { CGPoint(x: 0.5, y: $0) }

private let horizontalPoints: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
    .map { CGPoint(x: $0, y: 0.5) }

// MARK: - Stroke count mismatch

struct DTWMatcherStrokeCountTests {

    private let matcher = DTWMatcher()

    @Test("Empty templates always produce score 0")
    func emptyTemplatesReturnZero() {
        let strokes = [makeStroke(points: verticalPoints)]
        #expect(matcher.score(strokes: strokes, against: []) == 0)
    }

    @Test("One extra stroke is penalised by 25 points")
    func oneExtraStrokePenalty() {
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        let strokes = [
            makeStroke(points: verticalPoints),
            makeStroke(points: horizontalPoints),
        ]
        #expect(matcher.score(strokes: strokes, against: templates) == 75)
    }

    @Test("Two extra strokes are penalised by 50 points")
    func twoExtraStrokesPenalty() {
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        let strokes = [
            makeStroke(points: verticalPoints),
            makeStroke(points: horizontalPoints),
            makeStroke(points: horizontalPoints),
        ]
        #expect(matcher.score(strokes: strokes, against: templates) == 50)
    }

    @Test("Four extra strokes clamps to 0, not negative")
    func manyExtraStrokesClampsToZero() {
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        let strokes = Array(repeating: makeStroke(points: verticalPoints), count: 5)
        #expect(matcher.score(strokes: strokes, against: templates) == 0)
    }

    @Test("One missing stroke is penalised by 25 points")
    func oneMissingStrokePenalty() {
        let templates = [
            makeTemplate(verticalPoints, index: 0, direction: .topToBottom),
            makeTemplate(horizontalPoints, index: 1, direction: .leftToRight),
        ]
        let strokes = [makeStroke(points: verticalPoints)]
        #expect(matcher.score(strokes: strokes, against: templates) == 75)
    }

    @Test("Empty stroke list against one template is penalised by 25 points")
    func noStrokesAgainstTemplates() {
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        // abs(0 strokes - 1 template) = 1 mismatch → 100 - 25 = 75
        #expect(matcher.score(strokes: [], against: templates) == 75)
    }
}

// MARK: - Direction scoring

struct DTWMatcherDirectionTests {

    private let matcher = DTWMatcher()

    @Test("Drawing topToBottom when topToBottom expected produces score above 90")
    func correctTopToBottomDirection() {
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        let strokes   = [makeStroke(points: verticalPoints)]
        #expect(matcher.score(strokes: strokes, against: templates) > 90)
    }

    @Test("Drawing bottomToTop when topToBottom expected reduces score")
    func wrongDirectionTopToBottomReducesScore() {
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        // Draw upward: same path but reversed.
        let reversedPoints = verticalPoints.reversed() as [CGPoint]
        let strokes = [makeStroke(points: reversedPoints)]
        let score = matcher.score(strokes: strokes, against: templates)
        // Wrong direction: direction score = 20; DTW path score high (path is same shape).
        // final ≈ 20*0.4 + ~100*0.6 = 8 + 60 = 68
        #expect(score < 80, "Expected penalty for wrong direction, got \(score)")
    }

    @Test("Drawing leftToRight when leftToRight expected produces score above 90")
    func correctLeftToRightDirection() {
        let templates = [makeTemplate(horizontalPoints, direction: .leftToRight)]
        let strokes   = [makeStroke(points: horizontalPoints)]
        #expect(matcher.score(strokes: strokes, against: templates) > 90)
    }

    @Test("Drawing rightToLeft when leftToRight expected reduces score")
    func wrongDirectionLeftToRightReducesScore() {
        let templates = [makeTemplate(horizontalPoints, direction: .leftToRight)]
        let reversedPoints = horizontalPoints.reversed() as [CGPoint]
        let strokes = [makeStroke(points: reversedPoints)]
        #expect(matcher.score(strokes: strokes, against: templates) < 80)
    }

    @Test("Curved strokes receive a fixed direction score of 80 regardless of shape")
    func curvedStrokeDirectionIsAlways80() {
        // A diagonal stroke drawn against a curved template — path won't be great,
        // but the direction component should always contribute 80 * 0.4 = 32.
        let circlePoints: [CGPoint] = stride(from: 0.0, through: 2.0 * .pi, by: .pi / 10)
            .map { CGPoint(x: 0.5 + 0.45 * cos($0), y: 0.5 + 0.45 * sin($0)) }
        let templates = [makeTemplate(circlePoints, direction: .curved)]
        // Draw a simple vertical stroke; path score will be low but direction score = 80.
        let strokes = [makeStroke(points: verticalPoints)]
        let score = matcher.score(strokes: strokes, against: templates)
        // Direction: 80 * 0.4 = 32. Even with a terrible path (low), score should be ≥ 32.
        #expect(score >= 30)
    }
}

// MARK: - Path similarity (DTW algorithm)

struct DTWMatcherPathTests {

    private let matcher = DTWMatcher()

    @Test("Identical point sequences score above 95")
    func identicalSequencesScoreHigh() {
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        let strokes   = [makeStroke(points: verticalPoints)]
        #expect(matcher.score(strokes: strokes, against: templates) > 95)
    }

    @Test("A perpendicular stroke against a vertical template scores low on path")
    func perpendicularPathScoresLow() {
        // Template: vertical. Drawn: horizontal. Direction is also wrong.
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        let strokes   = [makeStroke(points: horizontalPoints)]
        // After normalisation both become identical unit-square lines so DTW ≈ 100,
        // but direction is wrong (dx > 0 for horizontal, dy > 0 expected).
        // direction = 20, path ≈ 100: final ≈ 20*0.4 + 100*0.6 = 68
        let score = matcher.score(strokes: strokes, against: templates)
        #expect(score < 80)
    }

    @Test("A two-stroke letter drawn with correct paths scores above 85")
    func twoStrokeLetterScoresHigh() {
        let diagonalRight: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
            .map { CGPoint(x: 0.5 + $0 * 0.5, y: $0) }
        let diagonalLeft: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
            .map { CGPoint(x: 0.5 - $0 * 0.5, y: $0) }
        let templates = [
            makeTemplate(diagonalRight, index: 0, direction: .diagonal(angle: 45)),
            makeTemplate(diagonalLeft,  index: 1, direction: .diagonal(angle: -45)),
        ]
        let strokes = [
            makeStroke(points: diagonalRight),
            makeStroke(points: diagonalLeft),
        ]
        #expect(matcher.score(strokes: strokes, against: templates) > 85)
    }

    @Test("Score is always in the 0–100 range")
    func scoreIsAlwaysInRange() {
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        let strokes   = [makeStroke(points: horizontalPoints)]
        let score = matcher.score(strokes: strokes, against: templates)
        #expect(score >= 0 && score <= 100)
    }

    @Test("A longer drawn stroke that approximates the template still scores above 80")
    func longerStrokeWithSameShapeScoresHigh() {
        // Double the number of sample points — DTW should still match after normalisation.
        let denseVertical: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.05)
            .map { CGPoint(x: 0.5, y: $0) }
        let templates = [makeTemplate(verticalPoints, direction: .topToBottom)]
        let strokes   = [makeStroke(points: denseVertical)]
        #expect(matcher.score(strokes: strokes, against: templates) > 80)
    }
}

// MARK: - Real letter templates integration

struct DTWMatcherLetterIntegrationTests {

    private let matcher = DTWMatcher()

    @Test("Drawing T's strokes in the correct order scores above 85")
    func tLetterCorrectOrder() {
        let templates = StrokeTemplate.templates(for: "T")
        let strokes = templates.map { makeStroke(points: $0.points) }
        #expect(matcher.score(strokes: strokes, against: templates) > 85)
    }

    @Test("Drawing L's strokes in the correct order scores above 85")
    func lLetterCorrectOrder() {
        let templates = StrokeTemplate.templates(for: "L")
        let strokes = templates.map { makeStroke(points: $0.points) }
        #expect(matcher.score(strokes: strokes, against: templates) > 85)
    }

    @Test("Drawing V's strokes in the correct order scores above 85")
    func vLetterCorrectOrder() {
        let templates = StrokeTemplate.templates(for: "V")
        let strokes = templates.map { makeStroke(points: $0.points) }
        #expect(matcher.score(strokes: strokes, against: templates) > 85)
    }

    @Test("Drawing E's strokes in the wrong count is penalised (3 instead of 4)")
    func eLetterWrongStrokeCountPenalised() {
        let templates = StrokeTemplate.templates(for: "E")
        // Draw only 3 of the 4 strokes.
        let strokes = templates.prefix(3).map { makeStroke(points: $0.points) }
        let score = matcher.score(strokes: strokes, against: templates)
        #expect(score <= 75, "Expected stroke-count penalty, got \(score)")
    }

    @Test("Drawing A's strokes in reverse order reduces the score vs correct order")
    func aLetterReversedOrderScoresLower() {
        let templates = StrokeTemplate.templates(for: "A")
        let correctStrokes  = templates.map { makeStroke(points: $0.points) }
        let reversedStrokes = templates.reversed().map { makeStroke(points: $0.points) }
        let correctScore  = matcher.score(strokes: correctStrokes,  against: templates)
        let reversedScore = matcher.score(strokes: reversedStrokes, against: templates)
        // Both have the same count but reversed path matching should score lower.
        #expect(correctScore >= reversedScore)
    }
}
